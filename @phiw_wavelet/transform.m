function [wimg, oimgi] = transform(data, w, scales)
% transform - transforms data using wavelet transform w, up to scales
% Input
% data    - data to transform - up to 3 dimensions
% w       - wavelet object specifying transform
% scales  - degree of coursest scale
%
% Output
% wimg    - wavelet transformed data, in resized data matrix if necessary
% oimgi   - index limits to retrieve original data from (inverted) wimg
%           matrix
%
% $Id: transform.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
% embed data in appropriate size matrix for wt
[newdims oimgi] = inp2out(w, size(data));
wimg = zeros(newdims);
numdims = ndims2(newdims);
% do assign in funny way to generalize for dimensions
wimg = subsasgn(wimg, lims2subs(oimgi), data);
  
% transform
levs = levels(w, newdims, scales);
for d = 1:numdims
  [H{d} K{d}] = filters(w,newdims(d));
end

% in (up to) 3d
wimg = wt3d(wimg, H, K, scales);

return

