function m = phiw_expand(img, nvoxels, outvol)
% phiw_expand - expand (probably binary) image by 'voxels' no of voxels
%
%
% $Id: phiw_expand.m,v 1.1.1.1 2004/06/25 15:20:40 matthewbrett Exp $
  
if nargin < 2
  error('Need two input args');
end
if nargin < 3
  outvol = [];
end
if ischar(img)
  img = spm_vol(img);
end
if ~isstruct(img) & isempty(outvol)
  m = zeros(size(img));
elseif isempty(outvol)
  error('Need output volume information');
else
  if ischar(outvol)
    q         = outvol;
    outvol         = img;
    outvol.fname   = q;
    outvol.descrip = sprintf('Expanded image (%g,%g,%g)',nvoxels);
    if isfield(img,'descrip'),
      outvol.descrip = sprintf('%s - expanded (%g,%g,%g)',img.descrip, s);
    end;
  end
  m = spm_create_image(outvol);
end

nvoxels = nvoxels(:);
if length(nvoxels) == 1
  nvoxels = ones(3,1)*nvoxels;
end

for i = 1:3
  f{i} = ones(nvoxels(i)*2+1,1);
end

spm_conv_vol(img,m,f{:},-nvoxels);