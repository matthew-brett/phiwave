function wtobj = phiw_wvmask(voxmask,wtinfo,options)
% phiw_wvmask - returns wavelet eqivalent mask for given voxel mask
%
% $Id: phiw_wvmask.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
if nargin < 1
  voxmask = spm_get(1,'img','Voxel mask');
end
if nargin < 2
  wtinfo = [];
end
if nargin < 3
  options = struct('datatype','uint8');
end

wtinfo = fillafromb(wtinfo, struct('scales',1,'wavelet',phiw_wavelet));

if ischar(voxmask),voxmask=spm_vol(voxmask);end

% get unity wavelet
wv1 = unitywavelet(wtinfo.wavelet);

% wt voxel mask
wtobj = phiw_wvimg(voxmask,options,wv1,wtinfo.scales);

% levels, quadrants
[tmp qs nquads] = levels(wv1,size(wtobj.img),wtinfo.scales);

% expansion required
ex = width(wtinfo.wavelet)/2;

% cycle over blocks to do smoothing
for l = 1:wtinfo.scales+1
  if l > wtinfo.scales
    % at top level -> only one quadrant
    nquads = 2;
  end
  dims = lims2dims(qs{l}{1});
  for q = 1:nquads-1
    dblk = reshape(wtobj(l,q),dims);
    wtobj(l,q) = phiw_expand(dblk,ex);
  end
end

% rebinarize
wtobj.img(wtobj.img>0) = 1;