function subimnet
% SUBIMNET Sub Image Network for MR motion Correction
%
%
% Copyright David Atkinson 2022


% data parameters

dExtent = 8 ; % +/- displacement extent in pixels 

nTrain = 1024 ;     % number of training sets
nValidation = 128 ; % number of validation sets

% source data and slices, downsample to speed up development
slicesTrain = 12 ; % early development on one slice
slicesValidation = 10 ;
% % slicesTrain = [1:15 17:27] ;
% % slicesValidation = slicesTrain ; % same slices used, just samples that 
% are separated for training and validation (test is an unseen set)
% % slicesTest = 16 ;

imsz = 32 ;

load mri D  % in-built brain MR (128 x 128)
imgTrain      = imresize(single(D(:,:,1,slicesTrain)), [imsz imsz])  ;
imgValidation = imresize(single(D(:,:,1,slicesValidation)), [imsz imsz]) ;
% %imgTest       = imresize(single(D(:,:,1,slicesTest)), [imsz imsz]) ;

% Set shot sequence
N = size(imgTrain,1) ;  % number of phase encodes
nshot = 8 ;
npershot = N / nshot ;

shot2ky = cell(nshot,1) ;

for ishot = 1:nshot
  shot2ky{ishot} = ishot : npershot : N ; 
end

% Generate data for Train and Validation
% % [XTV, YTV] = genTVsubimages(imgTrain, imgValidation, shot, shot2ky, )
% Generate XTrain (image translated shot) and YTrain (the displacement)
% Similary for XValidation and YValidation
% Start with single image and shot

shot = 3; % shot number to which motion is applied in gensubimage

refShot = 1; % reference shot (the one that contains ky=0)

% transformatins to be applied in gensubimage
transTrain      = dExtent * 2 * (rand([nTrain      1])-0.5) ; % random, uniformly distributed displacements
transValidation = dExtent * 2 * (rand([nValidation 1])-0.5) ; % random, uniformly distributed displacements

[XTrain, YTrain, ~] =  gensubimage(imgTrain, shot, shot2ky, transTrain, nTrain, refShot) ;

[XValidation, YValidation, kValidation] = gensubimage(imgValidation, shot, shot2ky, transValidation, nValidation, refShot) ;

% This was originally taken from MATLAB demo and only the size of the input
% image changed.
% "Train Convolutional Neural Network for Regression"

layers = [
    imageInputLayer([N N 1])
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    averagePooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    averagePooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    dropoutLayer(0.2)
    fullyConnectedLayer(1)
    regressionLayer];


% Train network for inputs (difference image here, another possibility 
% might be each in a separate channel) against displacement

% epoch = run through all training samples
% miniBatchSize = number of samples used before update
% validation not used to set weights and biases in training, but may inform
% hyperparameters such as number of layers etc. Need in addition, a
% locked-away test set evaluated once at the end (and the model could then


miniBatchSize  = 128;
validationFrequency = floor(numel(YTrain)/miniBatchSize);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',miniBatchSize, ...
    'MaxEpochs',30, ...
    'InitialLearnRate',1e-3, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',20, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{XValidation,YValidation}, ...
    'ValidationFrequency',validationFrequency, ...
    'Plots','training-progress', ...
    'Verbose',false);

% Considered augmenter but a) easier to apply in classification problesm 
% (this is regression), b) cannot apply most transformations correctly to 
% difference image.

% augmenter = imageDataAugmenter('RandYTranslation',[-2 2]) ;
% augimds = augmentedImageDatastore([imsz imsz], XTrain, YTrain,'DataAugmentation',augmenter) ;
% net = trainNetwork(augimds,layers,options);

net = trainNetwork(XTrain,YTrain,layers,options) ;

% Predict 

YPredicted = predict(net, XValidation);

% -  -   -  -  
% Plots and Figures
figure('Name',['Training range (', char(datetime),')'])
nPlot = 21 ;
transPlot = linspace(-dExtent,dExtent,nPlot) ;
[XP,~] = gensubimage(imgTrain, shot, shot2ky, transPlot, nPlot, refShot) ;

tiledlayout('flow','TileSpacing','compact','padding','compact')
for iV = 1:nPlot
    nexttile
    imshow(XP(:,:,1,iV),[])
    title(num2str(transPlot(iV)))
end

figure('Name','Displacements')
plot(YValidation, YPredicted,'o')
xlabel('YValidation')
ylabel('YPredicted'), grid on
axis([-dExtent dExtent -dExtent dExtent])
hold on
plot([-dExtent dExtent],[-dExtent dExtent])


figure('Name','originals')
imshow(cat(2,imgValidation, imgTrain),[])

figure('Name','Images')
step = floor(nValidation/5) ;

Vdisp = 1:step:nValidation ;
nVdisp = length(Vdisp) ;

tiledlayout(2,nVdisp,'TileSpacing','compact','padding','compact','TileIndexing','columnmajor')

for iV = 1:nVdisp
    nexttile
    imcorr = shotCorrect(kValidation(:,:,Vdisp(iV)), shot, shot2ky, -YPredicted(Vdisp(iV))) ;
    imshow(abs(imcorr),[])
    title(['Corrected, error: ', num2str( transValidation(Vdisp(iV)) - YPredicted(Vdisp(iV)) )])

    nexttile
    imshow(abs(k2i(kValidation(:,:,Vdisp(iV)))),[])
    title(['Corrupt ', num2str(transValidation(Vdisp(iV)))])
end
end

% - - - -
function [imcorr] = shotCorrect(kbad, shot, shot2ky, tapply) 
% shotCorrection  Applies translation to the phase encode lines in a shot
%
% [imcorr] = shotCorrect(kbad, shot, shot2ky, tapply) 
%
% See also gensubimage d_apply_shot

kcorr = d_apply_shot(kbad, tapply, shot, shot2ky) ;
imcorr = k2i(kcorr) ;

end

% - - - -
function kout = d_apply_shot(kin, d, shot, shot2ky)
% d_apply_shot Apply displacement to all lines in a shot
% Currently FE motion

kout = kin ;
kshifted = d_apply(kin, [], [0 d 0], 1, [shot2ky{shot}]) ;
kout([shot2ky{shot}],:) = kshifted ;
end

% - - - -
function [X, Y, kbad] = gensubimage(img, shot, shot2ky, trans, n, refShot)
% GENSUBIMAGE Generate sub image
%
% [X, Y, kbad] = gensubimage(img, shot, shot2ky, trans, n, refShot)
%
% X is [ ny nx 1 n] and returned as the modulus data.
% Y is [n 1] 
% kbad is [ ny nx n]
%
% See also shotCorrection

X = zeros([size(img,1) size(img,2) 1 n]) ; % subsampled images
Y = zeros([n 1]) ; % displacements

kbad = zeros([size(img,1) size(img,2), n]) ;

ksp = i2k(img) ;

kref = zeros(size(img)) ;
kref([shot2ky{refShot}],:) = ksp([shot2ky{refShot}],:) ;
Xref = k2i(kref) ;

for iim = 1:n
    Y(iim) = trans(iim) ;
    kbad(:,:,iim) = d_apply_shot(ksp, trans(iim), shot, shot2ky) ;

    kzfill = zeros(size(img)) ;
    kzfill([shot2ky{shot}],:) = kbad([shot2ky{shot}],:,iim) ;

    X(:,:,1,iim) = abs(k2i(kzfill) - Xref) ;
end

end

