function r = eq(obj1, obj2)
% eq - == overloaded 
%
% $Id: eq.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

r = 0;
if all(obj1.wvol.dim(1:3)-obj2.wvol.dim(1:3))
  obj1 = doproc(obj1);obj2=doproc(obj2);
  r = all(obj1.img(:) == obj2.img(:));
end