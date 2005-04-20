function data = invert(wimg, w, scales, oimgi)
% invert  - inverts wt data using wavelet transform w, up to scales
% Input
% wimg    - wavelet transformed data to invert - up to 3 dimensions
% w       - wavelet object specifying transform
% scales  - degree of coursest scale
% oimgi   - index limits to retrieve original data from (inverted) wimg
%           if specified, returns data matrix in original size
%           if not, get data embedded in wt size matrix
%
% Output
% data    - wavelet inverted data, in resized data matrix if necessary
%
% $Id: invert.m,v 1.2 2005/04/20 15:18:23 matthewbrett Exp $
 
if nargin < 4
  oimgi = []; % do not reembed in original matrix
end

wdims = size(wimg);
numdims = ndims2(wdims);

% interting transform
levs = levels(w, wdims, scales);
for d = 1:numdims
  [t1 t2 RH{d} RG{d}] = get_filters(w,wdims(d));
end

% in (up to) 3d
wimg = iwtnd(wimg, RH, RG, scales);

% restore to original dimensions as necessary
if ~isempty(oimgi)
  data = subsref(wimg,lims2subs(oimgi));
else
  data = wimg;
end

return



