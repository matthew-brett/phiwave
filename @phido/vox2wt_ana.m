function [phiwD] = vox2wt_ana(phiwD, wtinfo)
% Does image and mask conversion for wavelet analysis from voxel analysis
% FORMAT [phiwD] = vox2wt_ana(phiwD, wtinfo)
% 
% Inputs 
% phiwD       - phido design object
% wtinfo      - structure containing wt info
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
% $Id: vox2wt_ana.m,v 1.1 2004/11/18 18:34:47 matthewbrett Exp $
  
if nargin < 2
  error('Need wavelet information');
end

% Check wtinfo structure
if ~isfield(wtinfo, 'scales')
  error('wtinfo.scales not set')
end

% Get images
if ~has_images(phiwD), error('Need images in design'); end
VY = get_images(phiwD);

% Get masking structure
xM = masking_struct(phiwD);
if isempty(xM), error('Need masking structure'), end

% Are the images WT'ed?
wvobj = phiw_wvimg(VY(1),struct('noproc',1));
do_wt = 1;
if isempty(wvobj) % no they're not
  vy_wted = 0;
else              % yes they are
  vy_wted = 1;
  % Are the images WT'ed as we would like?
  if same_wtinfo(wvobj, wtinfo)
    % Yes - keep these VYs
    VT_wt = VY;
    do_wt = 0;
  end
end
if do_wt, [VY_wt wvobj] = phiw_volsub(VY, wtinfo); end

% Check if the mask matches the current wtinfo. If not, we will need the
% original images to calculate the mask from.
redo_xm = 1;
if isfield(xM, 'wave')
  if same_wtinfo(xM.wave, wtinfo)
    redo_xm = 0;
  else
    if vy_wted % we need original images back
      VY = phiw_wvimg('orig_vol', VY);
    end
  end
end

if redo_xm, xM = sf_make_mask(xM, VY, wtinfo); end

% return new design
phiwD = set_images(phiwD, VY_wt);
phiwD = masking_struct(phiwD, xM);

return

% Subfunctions
% ------------

function xM = sf_make_mask(xM, VY, wtinfo)
% Process and recreate masking structure
% FORMAT xM = sf_make_mask(xM, VY, wtinfo)

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
wvVM = phiw_wvmask(VM,wtinfo);

% save new mask
fprintf(' Saving the wavelet transformed mask as %s...', wvVM.wvol.fname);
wvm = write_wtimg(wvVM);
fprintf('...done\n');
  
% make new masking structure
xM = struct(...
    'TH',ones(size(VY))*-Inf,...
    'T', -Inf,...
    'I', 0,...
    'VM',wvVM.wvol, ...
    'xs', struct(...
	'Analysis_threshold','None (-Inf)',...
	'Explicit_masking', 'Yes'),...
     'wave', thin(wvm));

return