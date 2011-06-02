function res = dim_div(o, num)
% method to get/set number to divide dim by to get filter width
% FORMAT res = dim_div(o, num)
% 
% get: n = dim_div(o);
% set: o = dim_div(o, num)
%
% $Id: dim_div.m,v 1.1 2004/09/26 07:52:12 matthewbrett Exp $
  
if nargin < 2
  % get
  res = o.dim_div;
else
  % set
  o.dim_div = num;
  res = o;
end