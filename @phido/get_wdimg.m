function [Vdcon, Vderr, pD, changef] = get_wdimg(pD, Ic, wdstruct, fname) 
% calculates and returns denoised image in voxel space
% FORMAT [Vdcon Vderr] = get_wdimg(pD, Ic, wdstruct, fname)
%   
% Inputs (defaults in [square brackets])
% pD         - phido design object
% Ic         - vector of contrast numbers defining statistic image [GUI]
%              if length(Ic)>1 = conjunction. In this case the
%              contrasts should be in orthogonalization order
% wdstruct   - structure with info for wavelet denoising.  Fields are:
%              'thcalc' - wavelet denoising type ['stein']
%              'thapp' - form of wavelet denoising ['linear']
%              'ncalc' - null hypothesis calculation ['n']
%              'alpha' - alpha for t etc Bonferroni etc correction [0.05]
% fname      - filename for denoised image [via GUI]
%
% Returns
% Vdcon      - spm vol struct for denoised image
% Vderr      - spm vol struct for error image
% pD         - possibly modified phido object (contrasts entereed)
% changef    - whether the object was modified or not
%
% Based on spm_getSPM from the spm99 distribution
% (spm_getSPM, v2.35 Andrew Holmes, Karl Friston & Jean-Baptiste Poline 00/01/2)
%
% Matthew Brett, Federico Turkheimer, 9/10/00
% error maps added 19/11/01 - RP
%
% $Id: get_wdimg.m,v 1.1 2005/04/20 20:25:58 matthewbrett Exp $
  
if nargin < 2
  Ic = [];
end
if nargin < 3
  wdstruct = [];
end
if nargin < 4
  fname = '';
end

% default denoising - see comments above
def_struct = struct(...
    'thcalc', 'stein', ...
    'thapp', 'linear', ...
    'ncalc', 'n', ...
    'alpha', 0.05);

wdstruct = mars_struct('fillafromb', def_struct, wdstruct);

% check if can write to current directory
if ~swd_writable(pD)
  error(['Sorry, cannot write to directory: ' swd(pD)]);
end

%-Get Stats data from SPM.mat
%-----------------------------------------------------------------------
xX     = design_structure(pD);

%-Get/Compute mm<->voxel matrices & image dimensions from SPM.mat
%-----------------------------------------------------------------------
VY = get_images(pD);
M     = VY(1).mat;
iM    = inv(M);
DIM   = VY(1).dim(1:3);

%-Contrasts
%=======================================================================
if isempty(Ic)
  % only single t contrast allowed for the moment
  [Ic, pD, changef] = ui_get_contrasts(pD, ...
				       'T',1,...
				       'Select contrast...',..
				       '',...
				       wOK);
end

% get filename if necessary
%=======================================================================
if length(Ic)==1
  str  = sprintf('con%04d_%s',Ic,xCon(Ic).name);
else
  str  = [sprintf('contrasts {%d',Ic(1)),...
	  sprintf(',%d',Ic(2:end)),'}'];
end
if isempty(fname)
  fname = spm_input('Filename for contrast', 1, 's', ...
		    ['phiw_' mars_utils('str2fname',str)]);
end
Qdir = spm_str_manip(fname,'Hv');
fname = [spm_str_manip(fname,'stv'),'.img'];
if ~strcmp(Qdir, '.')
  fprintf('Note: writing image to current directory');
end

% write con and statistic images
%=======================================================================
[pD, Ic, changef, rmsi] = write_contrasts(pD,Ic);

% get contrasts 
xCon = get_contrasts(pD);
erdf = error_df(pD);
edf   = [xCon(Ic(1)).eidf erdf];

% get contrast and error image
wvcon = phiw_wvimg(xCon(Ic(1)).Vcon,struct('noproc',0),wave);
wverr = phiw_wvimg(spmmat.VResMS,struct('noproc',1),wave);
wverr.img = sqrt(rmsi.*(xCon(Ic(1)).c'*xX.Bcov*xCon(Ic(1)).c));

% do wavelet denoise/inversion
%=======================================================================
% denoising (which also removes NaNs)
fprintf('\t%-32s: %30s','Wavelet image','...denoising')         %-#
statinf = struct('stat','T','df',edf(2));
[wvcond wverr] = denoise(wvcon,wverr,statinf,phiw.denoise);
fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

% default error map return
Vderr = [];

% check there is still some signal
if all(wvcond(:)==0)
  warning('No wavelet coefficients survive thresholding')
  Vdcon = [];
  return
end

% inverse wavelet transform and save denoised image
Vdcon = struct(...
    'fname',  fullfile(swd,fname),...
    'dim',    [1 1 1,16],...
    'mat',    wave.ovol.mat,...
    'pinfo',  [1,0,0]',...
    'descrip',sprintf('PhiWave{%c} - %s',...
		      xCon(1).STAT,str));
Vdcon = write_iwtimg(wvcond,Vdcon);
fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

% Write description into text file
write_descrip(wvcond,Vdcon);

% Create error map, if we have used linear thresholding
if strcmp(phiw.denoise.thapp, 'linear')
  [pn fn ext] = fileparts(fname);
  efname = fullfile(pn, ['err_' fn ext]);
  % inverse wavelet transform and save error image
  Vderr = struct(...
      'fname',  fullfile(swd,efname),...
      'dim',    [1 1 1,16],...
      'mat',    wave.ovol.mat,...
      'pinfo',  [1,0,0]',...
      'descrip',sprintf('PhiWave{%c} - error:%s',...
			xCon(1).STAT,str));
  Vderr = write_iwtimg(wverr,Vderr);
  fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#
end
return