function res = num_coeffs(o, num)
% method to get/set number of coefficients
% FORMAT res = num_coeffs(o, num)
% 
% get: n = num_coeffs(o);
% set: o = num_coeffs(o, num)
%
% $Id: num_coeffs.m,v 1.1 2004/09/26 03:51:49 matthewbrett Exp $
  
if nargin < 2
  % get
  res = o.num_coeffs;
else
  % set
  [H G RH RG] = daub(num);
  res = set_filters(o, H, G, RH, RG);
end