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
% $Id: invert.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $
 
if nargin < 4
  oimgi = []; % do not reembed in original matrix
end

wdims = size(wimg);
numdims = ndims2(wdims);

% inverting transform
levs = levels(w, wdims, scales);
for d = 1:numdims
  [t t2 fs(d).sH fs(d).sK] = filters(w,wdims(d));
end

% in (up to) 3d
switch(numdims)
 case 1
  data = iwt(wimg,fs.sH,fs.sK,scales);
 case 2
  data = iwt2d(wimg,fs.sH,fs.sK,scales);
case 3
  for d=scales:-1:1,
    levinds = lims2subs(levs{d});
    level = subsref(wimg, levinds);
    [nx ny nz] = size(level);
    % Inverting in the z axis
    for x=1:nx, 
      for y=1:ny,
	level(x,y,:) = iwt(level(x,y,:),fs(3).sH,fs(3).sK,1);
      end
    end

    % Inverting in the x-y plane
    for z=1:nz, 
      level(:,:,z) = iwt2d(level(:,:,z),fs(1).sH,fs(1).sK,1);
    end
    
    wimg = subsasgn(wimg,levinds,level);
  end
 otherwise
  error('Haven''t done more than three dimensions yet')
end

% restore to original dimensions as necessary
if ~isempty(oimgi)
  data = subsref(wimg,lims2subs(oimgi));
else
  data = wimg;
end

return