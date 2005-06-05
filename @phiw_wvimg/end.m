function e = end(obj,K,N)
% end method for phiw_wvimg object
% The indexing for the wvimg object works thus:
% For one index (eg wvimg(2)) the whole level is returned (as a vector)
% For two (eg wvimg(2,4) the quadrant from the level is returned (as a
% vector)
% For three, (wvimg(2, 5, 10)) the voxel value is returned for the
% contained object.
%
% $Id: end.m,v 1.3 2005/06/05 04:42:22 matthewbrett Exp $

if N == 3
  % img case
  e = obj.wvol.dim(K);
elseif K == 1  % levels 
  e = obj.scales+1;
else  % two indices, K == 2 -> quadrants
  e = 2^3-1;
end