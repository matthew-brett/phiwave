function wtobj = pr_wvmask(voxmask, params, options)
% pr_wvmask - returns wavelet eqivalent mask for given voxel mask
% FORMAT wtobj = pr_wvmask(voxmask, params, options)
%
% Inputs
% voxmask     - voxel mask image name / vol struct
% params      - struct with wavelet and other parameters
%               Fields:
%                 scales     - wavelet scales
%                 wavelet    - phiw_wavelet object
%                 maskthresh - threshold for mask
%               and any other options that may be useful for the
%               phiw_wvimg object (see phiw_wvimg constructor)
% options     - any other options for creation of phiw_wvimg object
% 
% Outputs
% wtobj       - phiw_wvimg object with transformed mask
% 
% $Id: pr_wvmask.m,v 1.1 2005/04/20 15:09:08 matthewbrett Exp $
  
if nargin < 1
  voxmask = spm_get(1,'img','Voxel mask');
end
if nargin < 2
  params = [];
end
if nargin < 3
  options = [];
end

params = mars_struct('ffillmerge', params, options);

def_struct = struct('scales',1, ...
		    'wavelet',phiw_wavelet, ...
		    'maskthresh', 0.05, ...
		    'datatype','uint8');

params = mars_struct('fillafromb', params, def_struct);

if ischar(voxmask),voxmask=spm_vol(voxmask);end

% get unity wavelet
wv1 = unitywavelet(params.wavelet);

% wt voxel mask
wtobj = phiw_wvimg(voxmask, ...
		   struct('datatype', params.datatype), ...
		   wv1, ...
		   params.scales);

% levels, quadrants
[tmp qs nquads] = levels(wv1,size(wtobj.img),params.scales);

% expansion required
ex = width(params.wavelet)/2;

% cycle over blocks to do smoothing
for l = 1:params.scales+1
  if l > params.scales
    % at top level -> only one quadrant
    nquads = 2;
  end
  dims = lims2dims(qs{l}{1});
  for q = 1:nquads-1
    dblk = reshape(wtobj(l,q),dims);
    wtobj(l,q) = pr_expand(dblk,ex);
  end
end

% rebinarize
wtobj.img(wtobj.img>params.maskthresh) = 1;