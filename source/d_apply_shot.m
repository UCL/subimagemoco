function kout = d_apply_shot(kin, d, shot, shot2ky)
% d_apply_shot Apply displacement to all lines in a shot
% Currently applies only FE motion
%
%  kout = d_apply_shot(kin, d, shot, shot2ky)
%
%  kin      2D k-space
%  d        translation to be applied
%  shot     number of the shot to which motion is applied in FE direction
%  shot2ky  cell array 
%
%  kout     output k-space, kin with ky lines of shot altered
%  
% Copyright 2022, David Atkinson, University College London.
%
% See also subimagemoco d_apply_subimagemoco

kout = kin ;
kshifted = d_apply_subimagemoco(kin, [], [0 d 0], 1, [shot2ky{shot}]) ;
kout([shot2ky{shot}],:) = kshifted ;

end