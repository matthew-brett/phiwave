function tf = all_null(obj)
% returns 1 if all values in object images are NaN or zero
%
% $Id: all_null.m,v 1.1 2005/05/30 16:41:43 matthewbrett Exp $
  
tf = 1;
obj = doproc(obj);
img = obj.img(:);
img = img(~isnan(img));
if isempty(img), return, end
tf = all(img == 0);