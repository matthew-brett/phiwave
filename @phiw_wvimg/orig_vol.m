function VY = orig_vol(wvobj)
% returns original vol structs from (array of) phiw_objects
%
% $Id: orig_vol.m,v 1.1 2004/11/18 18:42:23 matthewbrett Exp $
  
for v = 1:prod(size(wvobj))
  VY(v) = wvobj(v).ovol;
end
VY = reshape(VY, size(wvobj));