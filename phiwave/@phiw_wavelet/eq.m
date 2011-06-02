function r = eq(obj1, obj2)
% overloaded == function for wavelet object
%
% $Id: eq.m,v 1.3 2005/06/05 04:42:22 matthewbrett Exp $

myclass = 'phiw_wavelet';

if ~(isa(obj1, myclass) & isa(obj2, myclass)), r = 0; return, end
r = strcmp(descrip(obj1), descrip(obj2));