function [VY,xM] = phiw_vox2wvana(VY, xM, phiw)
% Set options for wavelet analysis from voxel analysis
% FORMAT  [VY xM] = phiw_vox2wvana(VY, xM, wtinfo)
% 
% Inputs 
% VY          - vol structs for voxel images
% xM          - mask information for voxel analysis
% phiw        - structure containing wt, stats defaults
%
% Outputs
% VY          - vol structs for wavelet transformed images
% xM          - new masking structure in wavelet space
%
% Matthew Brett 9/10/00
%
% $Id: phiw_vox2wvana.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
if nargin < 2
  error('Need VY and xM as inputs')
end
if nargin < 3
  phiw = spm('getglobal', 'PHIWAVE');  
end

% get stats and wt stuff
wtinfo = phiw.wt;
stinfo = phiw.statistics;

% Check wtinfo structure
if ~isfield(wtinfo, 'scales')
  error('wtinfo.scales not set, check PhiWave defaults')
end

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
  
% wt and write VY volumes, as necessary
[VY wvobj] = phiw_volsub(VY, wtinfo);

% make new masking structure
xM = struct(...
    'TH',ones(size(VY))*-Inf,...
    'T', -Inf,...
    'I', 0,...
    'VM',wvVM.wvol, ...
    'xs', struct(...
	'Analysis_threshold','None (-Inf)',...
	'Explicit_masking', 'Yes'),...
    'wave', thin(wvobj));  % last gives info on wave transform

return