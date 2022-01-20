function subimnet
% SUBIMNET Sub Image Network for MR motion correction
%
%
% Copyright 2022, David Atkinson, University College London
%
% See also gensubimage randDisplacement


dExtent = 8 ; % +/- displacement extent in pixels 

nTrain = 1024 ;     % number of training sets
nValidation = 128 ;    % number of validation sets
nTest = 128 ;          % number of test data sets

% Using downsampled data from in-built mri
slicesTrain = [1:15 17:27] ;
slicesValidation = slicesTrain ; % same slices used, samples  
       % are separated for training and validation (test is an unseen slice)
slicesTest = 16 ;

imsz = 32 ;  % Size of images after downsampling

load mri D  % in-built brain MR (128 x 128)
imgTrain      = imresize(double(D(:,:,1,slicesTrain)), [imsz imsz])  ;
imgValidation = imresize(double(D(:,:,1,slicesValidation)), [imsz imsz]) ;
imgTest       = imresize(double(D(:,:,1,slicesTest)), [imsz imsz]) ;

% Set shot sequence
N = size(imgTrain,1) ;  % number of phase encodes
nshot = 8 ;
npershot = N / nshot ;

disp(['N: ',num2str(N),', nshot: ',num2str(nshot),', npershot: ', num2str(npershot)])

shot2ky = cell(nshot,1) ;

for ishot = 1:nshot
  shot2ky{ishot} = ishot : npershot : N ; 
end


% Generate XTrain (difference image of translated shot and refShot) and 
% YTrain (the applied displacement)
% Similary for XValidation and YValidation

shot = 3; % shot number to which motion is applied in gensubimage

refShot = 1; % reference shot number (the one that contains ky=0)

% transformations to be applied in gensubimage
transTrain      = randDisplacement(dExtent, nTrain) ;
transValidation = randDisplacement(dExtent, nValidation) ;
transTest       = randDisplacement(dExtent, nTest) ;

[XTrain, YTrain, ~] =  gensubimage(imgTrain, shot, shot2ky, transTrain, nTrain, refShot) ;

[XValidation, YValidation, ~] = gensubimage(imgValidation, shot, shot2ky, transValidation, nValidation, refShot) ;

[XTest, YTest, kTest] =  gensubimage(imgTest, shot, shot2ky, transTest, nTest, refShot) ;

% This layer arrangement was originally taken from the MATLAB help pages
% "Train Convolutional Neural Network for Regression"
% and only the size of the imageInputLayer changed.


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

% Definitions
% epoch = run through all training samples
% miniBatchSize = number of samples used before update
% validation not used to set weights and biases in training, but may inform
% hyperparameters such as number of layers etc. Need in addition, a
%  locked-away test set evaluated once at the end (and the model could then


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

% Considered use of MATLAB augmenter but 
%   a) easier to apply in classification problems (this is regression), 
%   b) cannot apply most transformations correctly to difference image within epochs.

% augmenter = imageDataAugmenter('RandYTranslation',[-2 2]) ;
% augimds = augmentedImageDatastore([imsz imsz], XTrain, YTrain,'DataAugmentation',augmenter) ;
% net = trainNetwork(augimds,layers,options);

net = trainNetwork(XTrain,YTrain,layers,options) ;

% Predict 

YPredictedValidation = predict(net, XValidation);
YPredictedTest       = predict(net, XTest);

% -  -   -  -  
% Plots and Figures to show outputs

tstamp = ['(',char(datetime),')'] ;

figure('Name',['Training range ', tstamp])
nPlot = 21 ;
transPlot = linspace(-dExtent,dExtent,nPlot) ;
[XP,~] = gensubimage(imgTrain, shot, shot2ky, transPlot, nPlot, refShot) ;

tiledlayout('flow','TileSpacing','compact','padding','compact')
for iV = 1:nPlot
    nexttile
    imshow(XP(:,:,1,iV),[])
    title(num2str(transPlot(iV)))
end

figure('Name',['Displacements ', tstamp])
plot(YValidation, YPredictedValidation,'bo'), hold on
plot(YTest, YPredictedTest,'ro')
xlabel('True Value')
ylabel('Network Predicted'), grid on
title('red test set, blue validation set')
axis([-dExtent dExtent -dExtent dExtent])
plot([-dExtent dExtent],[-dExtent dExtent])


eshow(imgValidation)

figure('Name',['Test Images ', tstamp])
step = floor(nTest/5) ;

Vdisp = 1:step:nTest ;
nVdisp = length(Vdisp) ;

tiledlayout(2,nVdisp,'TileSpacing','compact','padding','compact','TileIndexing','columnmajor')

for iV = 1:nVdisp
    nexttile
    imcorr = shotCorrect(kTest(:,:,Vdisp(iV)), shot, shot2ky, -YPredictedTest(Vdisp(iV))) ;
    imshow(abs(imcorr),[])
    title(['Corrected, error: ', num2str( transTest(Vdisp(iV)) - YPredictedTest(Vdisp(iV)) )])

    nexttile
    imshow(abs(k2i(kTest(:,:,Vdisp(iV)))),[])
    title(['Corrupt ', num2str(transTest(Vdisp(iV)))])
end

end  % end function






