function [Vdcon, Vderr, pD, changef] = get_wdimg(pD, Ic, wdstruct, fname) 
% calculates and returns denoised image in voxel space
% FORMAT [Vdcon, Vderr, pD, changef] = get_wdimg(pD, Ic, wdstruct, fname) 
%   
% Inputs (defaults in [square brackets])
% pD         - phido design object
% Ic         - vector of contrast numbers defining statistic image [GUI]
%              if length(Ic)>1 = conjunction. In this case the
%              contrasts should be in orthogonalization order
% wdstruct   - structure with info for wavelet denoising.  Fields are:
%              'thcalc' - wavelet denoising type ['stein']
%              'thapp'  - form of wavelet denoising ['linear']
%              'ncalc'  - null hypothesis calculation ['n']
%              'alpha'  - alpha for t etc Bonferroni etc correction [0.05]
%              't2z'    - if not 0, does T to Z transform on t data
%              'no_err' - if not 0, supresses writing of error image 
%
% fname      - filename for denoised image [via GUI]
%
% Returns
% Vdcon      - spm vol struct for denoised image
% Vderr      - spm vol struct for error image
% pD         - possibly modified phido object (contrasts entereed)
% changef    - whether the design object was modified or not
%
% Based on spm_getSPM from the spm99 distribution
% (spm_getSPM, v2.35 Andrew Holmes, Karl Friston & Jean-Baptiste Poline 00/01/2)
%
% Matthew Brett, Federico Turkheimer, 9/10/00
%
% $Id: get_wdimg.m,v 1.6 2005/05/31 11:11:01 matthewbrett Exp $
  
if nargin < 2
  Ic = [];
end
if length(Ic) > 1
  error('Can only get one denoised contrast at a time');
end
if nargin < 3
  wdstruct = [];
end
if nargin < 4
  fname = '';
end

% default return values
[Vdcon, Vderr] = deal([]);
changef = 0;

% default denoising - see comments above
def_struct = struct(...
    'thcalc', 'stein', ...
    'thapp', 'linear', ...
    'ncalc', 'n', ...
    'alpha', 0.05,...
    't2z', 0, ...
    'no_err', 0);

wdstruct = mars_struct('ffillsplit', def_struct, wdstruct);

% check if can write to current directory
if ~swd_writable(pD)
  error(['Sorry, cannot write to directory: ' swd(pD)]);
end

%-Get Stats data from SPM.mat
%-----------------------------------------------------------------------
xX     = design_structure(pD);

%-Get/Compute mm<->voxel matrices & image dimensions from SPM.mat
%-----------------------------------------------------------------------
VY    = get_images(pD);
M     = VY(1).mat;
iM    = inv(M);
DIM   = VY(1).dim(1:3);

%-Contrasts
%=======================================================================
if isempty(Ic)
  % only single t contrast allowed for the moment
  [Ic, pD, changef] = ui_get_contrasts(pD, ...
				       'T', ...
				       1, ...
				       'Select contrast...', ...
				       '', ...
				       1);
end

% get filename if necessary
%=======================================================================
xCon = get_contrasts(pD);
if isempty(fname)
  str  = sprintf('con%04d_%s',Ic,xCon(Ic).name);
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
[pD, Ic, changef, rmsi] = write_contrasts(pD, Ic);

% get contrasts 
if changef, xCon = get_contrasts(pD); end
xC1  = xCon(Ic);
erdf = error_df(pD);
edf   = [xC1.eidf erdf];

% get contrast and error image
wave = get_wave(pD);
wvcon = phiw_wvimg(xC1.Vcon,struct('noproc',0), wave);
VResMS = get_vol_field(pD, 'VResMS');
wverr = phiw_wvimg(VResMS,struct('noproc',1), wave);
wverr.img = sqrt(rmsi.*(xC1.c'*xX.Bcov*xC1.c));

% do wavelet denoise/inversion
%=======================================================================
% calculate denoising (which also removes NaNs)
statinf = struct('stat','T','df',edf(2));
if wdstruct.t2z, statinf.stat = 'TZ'; end
fprintf('\t%-32s: %30s','Wavelet image','...calculate denoising')         %-#
[th_obj, dndescrip] = thresh_calc(wvcon, wverr, statinf, wdstruct);
fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

% check there is still some signal
if all_null(th_obj)
  warning('No wavelet coefficients survive thresholding')
  return
end

% Apply thresholding to contrast image 
wvcond = thresh_apply(wvcon, th_obj, dndescrip);

% inverse wavelet transform and save denoised image
d_swd = swd(pD);
Vdcon = struct(...
    'fname',  fullfile(d_swd,fname),...
    'dim',    [1 1 1,16],...
    'mat',    wave.ovol.mat,...
    'pinfo',  [1,0,0]',...
    'descrip',sprintf('PhiWave{%c} - %s',...
		      xC1.STAT,xC1.name));
Vdcon = write_iwtimg(wvcond,Vdcon);
fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

% Write description into text file
write_descrip(wvcond,Vdcon);

% Create error map, if we have saved residuals
VResI = get_vol_field(pD, 'VResI');
if ~isempty(VResI) & ~wdstruct.no_err
  % Quite a lot of work to do here
  nScan = prod(size(VResI));
  oi = oimgi(wave);
  odim = diff(oi)+1;
  err_img = zeros(odim);
  sum_img = err_img;
    
  % get whole thresholding object as image, find mask
  th_img = as_matrix(th_obj);
  tmp = isfinite(th_img) & ~(th_img == 0);
  in_mask = find(tmp);
  out_mask = find(~tmp);
  th_img = th_img(in_mask);
  clear th_obj tmp;

  for i = 1:nScan
    obj = phiw_wvimg(VResI(i), [], wave);
    img = as_matrix(obj);
    img(out_mask) = 0;
    img(in_mask) = img(in_mask) .* th_img;
    img = invert(img, wave.wavelet, wave.scales, oi);
    sum_img = sum_img + img;
    err_img = err_img + img .^2;
  end
  xX = design_structure(pD);
  err_img = (err_img - (sum_img .^2 / nScan)) / xX.trRV;
  
  % save error image
  efname = fullfile(d_swd, ['err_' fname]);
  Vderr = struct(...
      'fname',  efname,...
      'dim',    [odim,16],...
      'mat',    wave.ovol.mat,...
      'pinfo',  [1,0,0]',...
      'descrip',sprintf('PhiWave{%c} - error:%s',...
			xC1.STAT,xC1.name));
  Vderr = spm_write_vol(Vderr, err_img);
  fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done');
end
return