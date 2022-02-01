function [X, Y, kbad] = gensubimage(imgin, shot, shot2ky, trans, nOut, refShot, imgOrder, cshifts)
% GENSUBIMAGE Generate sub images
%  Generates data for training, validation and testing.
%  For augmentation, picks images from 'slices' of imgin according to imgOrder, 
%  applies random offsets from cshifts
% Then applies the motion-corrupting displacements specified in trans.
%
% [X, Y, kbad] = gensubimage(imgin, shot, shot2ky, trans, nOut, refShot, imgOrder, cshifts)
%
% imgin [ ny nx 1 nSlice]  here nSlice is number of images supplied 
%  (nSlice could be slices or images from different subjects. 
%  'slices' picked at random)
% shot    shot number
% shot2ky cell array giving ky line numbers for given shot
% nOut    number of output images
% refShot number of shot treated as the reference (usually the one
%                            containing the ky=0 line, i.e. shot 1)
% imgOrder [nSlice 1]  indices of 'slices' from imgin to use.
% cshifts  [nSlice 2]  integer x and y shifts to be applied in augmentation
%
% X is [ ny nx 1 nOut]  subimages returned as modulus data. These are the
% difference between complex images of the refShot and the perturbed shot.
% Y is [nOut 1]         the translations applied
% kbad [ ny nx nOut]    k-space of the full data with one shot corrupted.
%
% Copyright 2022, David Atkinson, University College London
%
% See also d_apply_shot

X = zeros([size(imgin,1) size(imgin,2) 1 nOut]) ; % subsampled images
Y = zeros([nOut 1]) ; % displacements

nSlice = size(imgin,4) ; % These could be slices or different data sets
if max(imgOrder) > nSlice || min(imgOrder)<1
    error('imgOrder should index into imgin')
end
if length(imgOrder) ~= nOut
    error('Number of slices and order size mismatch')
end
if size(cshifts,1) ~= nOut
    error('Number of cshifts and images does not match')
end

kbad = zeros([size(imgin,1) size(imgin,2), nOut]) ;

for iim = 1:nOut
    % augmentation 
    
    img = imgin(:,:,1,imgOrder(iim)) ;

    % apply random integer shifts in x and y
    img=circshift(img,cshifts(iim,:)) ;

    ksp = i2k(img) ;

    kref = zeros([size(img,1) size(img,2)]) ;

    kref([shot2ky{refShot}],:) = ksp([shot2ky{refShot}],:) ;
    Xref = k2i(kref) ; % zero filled from refShot


    Y(iim) = trans(iim) ;
    kbad(:,:,iim) = d_apply_shot(ksp, trans(iim), shot, shot2ky) ;

    kzfill = zeros([size(img,1) size(img,2)]) ;
    kzfill([shot2ky{shot}],:) = kbad([shot2ky{shot}],:,iim) ;

    X(:,:,1,iim) = abs(k2i(kzfill) - Xref) ;
end

end