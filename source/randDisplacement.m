function trans = randDisplacement(dExtent, n)
% randDisplacement  Random Displacements 
%
% trans = randDisplacement(dExtent, n)
%
%  trans is [n 1] random uniformly distributed between +/- dExtent
%
% Copyright 2022, David Atkinson

trans = dExtent * 2 * (rand([n 1])-0.5) ; % random, uniformly distributed displacements

end