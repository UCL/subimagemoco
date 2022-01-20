function ph3D = d_apply_subimagemoco(k_in, kunits, delta_disp, varargin)
% COPY OF d_apply FROM PRIVATE AUTOFOCUS FOLDER 
% Apply in 3D, change in translational position.
% 
% A positive displacement of [1 1 1] moves the IMAGE, right, down and back
% by 1 unit. 
%
% Image translations applied by phase ramps in k-space.
%
% Note that unlike previous code, this returns only the altered portions
% of k-space.
%
% k_out = d_apply(kin, kunits, delta_disp)       % Defaults to whole data 
% k_out = d_apply(kin, kunits, delta_disp, DC )
% k_out = d_apply(kin, kunits, delta_disp, dim, planes)
% k_out = d_apply(kin, kunits, delta_disp, dim, planes, DC)
%
% If trying to shift the k-space by passing in the image domain, 
% rather than k-space. The delta_disp should be the negative of 
% that desired and in absolute spatial freq units. The variable
% kunits should be the absolute pixel sizes.
%
% [13 Dec, 1999  Note the input can be in the hybrid domain if the
%                displacement is solely in the k-space direction of
%                h-space ]
%
% INPUTs
%  k_in         Input k-space
%  kunits       1x3 array giving k-space stepsize. If this is 0, the
%               values are reset to 1/ny, 1/nx, 1/nz - making
%               delta_disp be in pixel units.
%               See my note "The Fourier Shift Theorem" for more
%               details /tristan2/da/notes/fshift.tex
%               kunits are the difference in spatial frequency betweem
%               one k-space point and the next.
%  delta_disp   nd x 3 array. Columns are yd, xd, zd
%               If nd = 1, the same translation is applied to every
%               section of k-space changed.
%               If nd = no. of planes, each row of changes is applied to 
%               the corresponding plane.
%               Units are pixel dimensions for this k-space size.
%  dim          The dimension of the planes (Y=1, X=2, Z=3)
%  planes       Translations are applied across planes in k-space. The
%               plane is in the dim dimension. (In the 2D case, a
%               plane is a PE line and the dimension is 1)
%
%  DC           [DCky DCkx DCkz] (calculated if not input)
%
% David Atkinson, July, 1998.
% @(#)d_apply.m	1.10 , created 07/17/02
%

% The coding in here needs a clear head for matrices and cell arrays!

narginchk(3,6) ;

Y = 1;
X = 2 ;
Z = 3 ;

[ny, nx, nz] = size(k_in) ;
siz_in = [ny, nx, nz]  ;
[nrdd,ncdd] = size(delta_disp) ;

if ncdd ~= 3
  error([ ' Displacements must have three columns , y, x and z, not ', ...
	num2str(ncdd) ])
end

if length(kunits) == 4 % assume derived from gipl with 4th dimension, chop
  kunits = kunits(1:3) ;
end

if length(kunits) ~= 3 | length(find(kunits==0)) ~= 0
%  disp([ 'Setting kunits to pixel dimensions'])
  kunits = [ 1/ny 1/nx 1/nz] ;
end

if nargin == 3
  dim = 1 ;
  planes = [ 1: siz_in(dim) ] ;
  DC = dc3D(k_in) ;
end

if nargin == 4
  dim = 1 ;
  planes = [ 1: siz_in(dim) ] ;
  DC = varargin{1} ;
end

if nargin == 5
  dim = varargin{1};
  planes = varargin{2} ;
  DC = dc3D(k_in) ;
end

if nargin == 6
  dim = varargin{1} ;
  planes = varargin{2} ;
  DC = varargin{3} ;
end

if length(DC) ~= 3
  warning([ 'DC must be a vector of length 3' ]) 
end

nplanes = length(planes) ;

if nrdd == 1
  delta_disp = repmat(delta_disp,nplanes,1) ;
  nrdd = nplanes ;
end

if nrdd ~= nplanes
  error([ 'delta_disp must have 1 row or the same as the number of planes' ])
end

mtwopii = -2i * pi  ;

% generate phase shifts

xvec = reshape(([1:nx] - DC(2)), [ 1 nx 1 ]) ;   % vector in x direction
yvec = reshape(([1:ny] - DC(1)), [ ny 1 1 ]) ;   % vector in y direction
zvec = reshape(([1:nz] - DC(3)), [  1 1 nz]) ;   % vector in z direction

% set the indices to the vectors in a cell array
ind_vec{1} = [1:siz_in(1)] ;
ind_vec{2} = [1:siz_in(2)] ;
ind_vec{3} = [1:siz_in(3)] ;

ind_vec{dim} = planes ;  % use only the specified planes in the dim dimension

% determine size of output array
nyout = length(ind_vec{1}) ;
nxout = length(ind_vec{2}) ;
nzout = length(ind_vec{3}) ;


% Next bit is a tad complicated. Designed to cope with plane being in 
% any dimension. Unfortunately, the delta_disp array is always Nx3 so
% lots of reshaping needs to be carried out. 
% At least this way x,y and z transformations are carried out in one
% go and can vary from plane to plane.
%

% ph3D = repmat(1,[nyout nxout nzout]) ; creates an array that is real
% only, i.e. half size. Not good for memory allocation.

ph3D = k_in(ind_vec{:}) ;

switch dim
  case 1   % Y
    yphvec = exp( (mtwopii * kunits(Y)) .*  ...
	delta_disp(:,1) .* yvec(ind_vec{1}) ); %y
    ph3D = ph3D .* repmat(yphvec,[1 nxout nzout]) ;
    
    xphvec = exp( (mtwopii * kunits(X)) .* ...
	repmat(delta_disp(:,2),[1 nxout]) .* ...    % y x x
	repmat(xvec,[nyout 1 1 ]) ) ;
    ph3D = ph3D .* repmat(xphvec,[1 1 nzout]) ;
    
    zphvec = exp( (mtwopii * kunits(Z)) .* ...
	repmat(delta_disp(:,3),[ 1 1 nzout]) .* ...   % y x 1 x z
	repmat(zvec,[nyout 1 1]) ) ;
    ph3D = ph3D .*  repmat(zphvec,[1 nxout 1]) ;

  case 2  % X
    xdisp = reshape(delta_disp(:,2),[1 nxout 1]) ;
    xphvec = exp( (mtwopii * kunits(X)) .* ...
	xdisp .* xvec(ind_vec{2})) ;
    ph3D = ph3D .* repmat(xphvec,[nyout 1 nzout]) ;
    
    yphvec = exp( (mtwopii *kunits(Y)) .* ...
	repmat(reshape(delta_disp(:,1),[1 nxout 1]),[nyout 1 1]) .* ...
	repmat(yvec,[1 nxout 1]) )  ;
    ph3D = ph3D .* repmat(yphvec,[1 1  nzout]) ;
    
    zphvec = exp( (mtwopii * kunits(Z)) .* ...
	repmat(reshape(delta_disp(:,3),[ 1 nxout 1]), [1 1 nzout]) .* ...
	repmat(zvec,[ 1 nxout 1 ])) ;
    ph3D = ph3D .* repmat(zphvec,[nyout 1 1]) ;
    
  case 3  % Z
    
    zphvec = exp( (mtwopii * kunits(Z)) .* ...
	reshape(delta_disp(:,3),[ 1 1 nzout]) .* zvec(ind_vec{3})) ;
    ph3D = ph3D .* repmat(zphvec,[nyout nxout 1]) ;
    
    xphvec = exp( (mtwopii * kunits(X)) .* ...
	repmat(reshape(delta_disp(:,2),[1 1 nzout]), [ 1 nxout 1]) .* ...
	repmat(xvec,[1 1 nzout]) ) ;
    ph3D = ph3D .* repmat(xphvec,[nyout 1 1]) ;
    
    yphvec = exp( (mtwopii * kunits(Y)) .* ...
	repmat(reshape(delta_disp(:,1),[1 1 nzout]) ,[nyout 1 1]) .* ...
	repmat(yvec,[1 1 nzout]) ) ;
    ph3D = ph3D .* repmat(yphvec,[1 nxout 1]) ;
    
end


% k_out = k_in(ind_vec{:}) .* ph3D ;




