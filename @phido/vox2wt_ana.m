function [phiwD] = vox2wt_ana(phiwD, params)
% Does image and mask conversion for wavelet analysis from voxel analysis
% FORMAT [phiwD] = vox2wt_ana(phiwD, wtinfo)
% 
% Inputs 
% phiwD       - phido design object
% params          - structure containing options as fields; [defaults]
%                   'wavelet'    - phiwave wavelet object to transform
%                      images [phiw_lemarie(2)] 
%                   'scales'     - scales for wavelet transform [4]
%                   'wtprefix'   - prefix for wavelet transformed files
%                      ['wv_']
%                   'maskthresh' - threshold for mask image [0.05]
%
% Outputs
% phiwD       - modified phido design object
% 
% The function first calculates the masking for the wavelet analysis, and
% stores results in the design masking structure.  It next checks if the
% images in the design are already WT'ed, by looking in their .mat file
% information.  If not, does WT and stores new vol structs in design
%
% Matthew Brett 9/10/00
%
% $Id: vox2wt_ana.m,v 1.3 2005/04/20 15:12:46 matthewbrett Exp $
  
% Default object structure
defparams = struct('wavelet',  phiw_lemarie(2), ...
		   'scales',   4, ...
		   'wtprefix', 'wv_', ...
		   'maskthresh', 0.05);

if nargin < 2
  params = [];
end
params = mars_struct('ffillsplit', defparams, params);

% Get images
if ~has_images(phiwD), error('Need images in design'); end
VY = get_images(phiwD);

% Get wt'ed and non wt'ed images from vols
g_wt_opts = struct('reproc', 1, ...
		   'verbose', verbose(phiwD), ...
		   'find_similar', 1);
for i = 1:prod(size(VY))
  [VY_wt(i) VY_o(i)] = sf_get_wted(VY(i), params, g_wt_opts);
end
VY_wt = reshape(VY_wt, size(VY));
VY_o  = reshape(VY_o, size(VY));

% Get masking structure
xM = masking_struct(phiwD);
if isempty(xM), error('Need masking structure'), end

% Check if the mask matches the current wt information. If not, we will need
% the original images to calculate the mask from.
if isfield(xM, 'wave')
  redo_mask = ~same_wtinfo(xM.wave, params)
else
  redo_mask = 1;
end
if redo_mask
  xM = sf_make_mask(xM, VY_o, params);
end

% return new design
phiwD = set_images(phiwD, VY_wt);
phiwD = masking_struct(phiwD, xM);

return

% Subfunctions
% ------------

function [Vw, Vo] = sf_get_wted(V, params, options)
% Takes vol struct, returned WT'ed, non WT'ed vol structs
% FORMAT [Vw, Vo] = sf_get_wted(V, params, options)
% 
% Input 
% V        - WT'ed or non WT'ed vol struct
% params   - wavelet transform infomation structure
% options  - structure containing none or more of the following fields as
%            options:
%              'reproc'  - redo WT on already WT'ed images, if parameters
%                 dont match wtinfo
%              'verbose' - display messages
%              'find_similar' - if processing image, look for appropriate
%                 previously transformed image
% 
% Images can be: 
% Voxel images (not WTed) -> return to-be-WTed object
% WT'ed images -> return WT'ed object
% Voxel images with matching WT'ed image -> return WT'ed object

f_s = mars_struct('getifthere', options, 'find_similar');  
wv_opts = struct('noproc', 1, 'wtprefix', params.wtprefix, ...
		 'find_similar', f_s);

% Flag whether to reprocess if already WT'ed but with wrong parameters
reproc_f = mars_struct('isthere', options, 'reproc');

if phiw_wvimg('is_wted', V)  % already transformed

  % Are the images WT'ed as we would like?
  Vo = phiw_wvimg('orig_vol', V);
  wvobj = phiw_wvimg(V, wv_opts);
  if same_wtinfo(wvobj, params) % yes
    Vw = V;
    return
  end
  
  % no, maybe reprocess
  if ~reproc_f
    error(sprintf('%s is already WTed with different parameters', ...
		  V.fname))
  end
  options.find_similar = 0;
  [Vw, Vo] = sf_get_wted(Vo, params, options);
  return

end  

% Make wvimg object, maybe looking for compatible already processed
% image
wvobj = phiw_wvimg(V, wv_opts, params.wavelet, params.scales);
if ~is_wted(wvobj)
  wvobj = write_wtimg(wvobj);
end
Vw = wv_vol(wvobj);
Vo = V;

return

function xM = sf_make_mask(xM, VY, params)
% Process and recreate masking structure
% FORMAT xM = sf_make_mask(xM, VY, params)

% masking, first
%-If xM is not a structure then assumme it's a vector of thresholds
%------------------------------------------------------------------
if ~isstruct(xM)
  xM = struct(	'T',	[],...
		'TH',	xM,...
		'I',	0,...
		'VM',	{[]},...
		'xs',	struct('Masking','analysis threshold'));
end

% mask in voxel space
mask = zeros(VY(1).dim(1:3));

% Create masking image 
if isempty(xM.TH)
  xM.TH = zeros(size(VY))-Inf;
  thmf = 0;
else
  thmf = any(xM.TH(:) ~= -Inf);
end
[vol X Y Z] = deal(VY(1),1,2,3);
% plane coordinate stuff
plsz = prod(vol.dim(X:Y));
xords  = [1:vol.dim(X)]'*ones(1,vol.dim(Y)); %-plane X coordinates
yords  = ones(vol.dim(X),1)*[1:vol.dim(Y)];  % plane Y coordinates
tPl = [xords(:) yords(:)]';
% implicit 0 masking flag vector
YNaNrep = spm_type(VY(1,1).dim(4),'nanrep');
IM = xM.I & ~YNaNrep & xM.TH(:,1)<0;
	
fprintf(' Calculating masking image...');
% cycle over planes
for z = 1:vol.dim(3)
  pPl = tPl; % xyz of current in mask points
  pPl(Z,:) = ones(1, plsz)*z;
  % intensity thresholding
  if thmf
    for i = 1:prod(size(VY))
      if isempty(pPl), break,end
      vals = spm_sample_vol(VY(i),pPl(X,:),pPl(Y,:),pPl(Z,:),0);
      msk = vals>xM.TH(i);
      if IM(i), msk = msk & abs(vals)>eps; end
      pPl = pPl(:, msk);
    end
  end
  % explicit masking images
  for i = 1:prod(size(xM.VM))
    if isempty(pPl), break,end
    tM   = inv(xM.VM(i).mat)*vol.mat;		%-Reorientation matrix
    tmp  = tM * [pPl;ones(1,size(pPl,2))];	%-Coords in mask image
    
    %-Load mask image within current mask & update mask
    %--------------------------------------------------
    vals = spm_sample_vol(xM.VM(i),tmp(X,:),tmp(Y,:),tmp(Z,:),0);
    pPl = pPl(:, vals>0);
  end
  if ~isempty(pPl)
    inds = pPl(X,:)+(pPl(Y,:)-1)*vol.dim(X)+(z-1)*plsz;
    mask(inds) = 1;
  end
end
fprintf('...done\n');

% write mask image in voxel space
VM = struct('fname',	'voxmask.img',...
	    'dim',      [vol.dim(1:3),spm_type('uint8')],...
	    'mat',      vol.mat,...
	    'pinfo',	[1 0 0]',...
	    'descrip',	'phiw:resultant analysis mask');
fprintf(' Saving the intial analysis mask as %s ...', VM.fname);
spm_write_vol(VM, mask);
fprintf('...done\n');

% Transform, do processing for wavelet space mask
wvVM = pr_wvmask(VM, params);

% save new mask
fprintf(' Saving the wavelet transformed mask as %s...', wvVM.wvol.fname);
wvm = write_wtimg(wvVM);
fprintf('...done\n');
  
% make new masking structure
xM = struct(...
    'TH',ones(size(VY))*-Inf,...
    'T', -Inf,...
    'I', 0,...
    'VM',wvm.wvol, ...
    'xs', struct(...
	'Analysis_threshold','None (-Inf)',...
	'Explicit_masking', 'Yes'),...
     'wave', thin(wvm));

return