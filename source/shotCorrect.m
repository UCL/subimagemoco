function [imcorr] = shotCorrect(kbad, shot, shot2ky, tapply) 
% shotCorrection  Applies translation to the phase encode lines of a shot
%
% [imcorr] = shotCorrect(kbad, shot, shot2ky, tapply) 
%
% Copyright 2022, David Atkinson, University College London
%
% See also gensubimage d_apply_shot

kcorr = d_apply_shot(kbad, tapply, shot, shot2ky) ;
imcorr = k2i(kcorr) ;

end
