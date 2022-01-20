function [X, Y, kbad] = gensubimage(imgin, shot, shot2ky, trans, n, refShot)
% GENSUBIMAGE Generate sub images
%  Generates data for training, validation and testing.
%  For augmentation, picks images from 'slices' of imgin at random, 
%  applies random offset in (integer steps between -2 and 2 in x and y).
% Then applies the displacements specified in trans.
%
% [X, Y, kbad] = gensubimage(imgin, shot, shot2ky, trans, n, refShot)
%
% imgin [ ny nx nSlice]  here nSlice is number of images supplied 
%  (nSlice could be slices or images from different subjects. 
%  'slices' picked at random)
% shot    shot number
% shot2ky cell array giving ky line numbers for given shot
% n       number of output images
% refShot number of shot treated as the reference (usually the one
%                            containing the ky=0 line, i.e. shot 1)
% X is [ ny nx 1 n]  subimages returned as modulus data. These are the
% difference between complex images of the refShot and the perturbed shot.
% Y is [n 1]         the translations applied
% kbad [ ny nx n]    k-space of the full data with one shot corrupted.
%
% Copyright 2022, David Atkinson, University College London
%
% See also d_apply_shot

X = zeros([size(imgin,1) size(imgin,2) 1 n]) ; % subsampled images
Y = zeros([n 1]) ; % displacements

nSlice = size(imgin,3) ; % These could be slices or different data sets

kbad = zeros([size(imgin,1) size(imgin,2), n]) ;

for iim = 1:n
    % pick 'slice' at random
    randSlice = randi(nSlice) ;
    img = imgin(:,:,randSlice) ;

    % apply random integer shifts in x and y
    yshift = randi(5)-3;
    xshift = randi(5)-3;
    img=circshift(img,[yshift xshift]) ;

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