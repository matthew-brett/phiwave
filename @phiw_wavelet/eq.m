function r = eq(obj1, obj2)
% eq - == overloaded 
%
% $Id: eq.m,v 1.2 2004/11/18 19:00:14 matthewbrett Exp $

myclass = 'phiw_wavelet';

if ~(isa(obj1, myclass) & isa(obj2, myclass)), r = 0; return, end
r = strcmp(descrip(obj1), descrip(obj2));