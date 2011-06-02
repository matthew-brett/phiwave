function D = explicit_mask(D, mask_img)
% sets explicit mask into design
% FORMAT D = explicit_mask(D, mask_img)
% 
% Input
% D         - design
% mask_img  - image name or vol struct
% 
% Output
% D         - modified design
% 
% e.g.
% P = spm_get(1, 'img', 'Select mask image for design');
% D = explicit_mask(D,  P);
% 
% $Id: explicit_mask.m,v 1.1 2005/06/21 03:59:04 matthewbrett Exp $
  
if nargin < 2
  error('Need masking image');
end
if ischar(mask_img)
  mask_img = spm_vol(mask_img);
end

xM = masking_struct(D);
if isfield(xM, 'TH')
  xM.TH = ones(size(xM.TH)) * -Inf;
end
xM.VM = mask_img;
D = masking_struct(D, xM);