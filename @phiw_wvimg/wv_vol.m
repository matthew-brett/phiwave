function VY = wv_vol(wvobj)
% returns WT'ed vol structs from (array of) phiw_objects
%
% $Id: wv_vol.m,v 1.1 2005/04/06 22:36:02 matthewbrett Exp $
  
for v = 1:prod(size(wvobj))
  VY(v) = wvobj(v).wvol;
end
VY = reshape(VY, size(wvobj));