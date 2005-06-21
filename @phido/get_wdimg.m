function [Vdcon, Vderr, pD, changef] = get_wdimg(pD, Ic, wdstruct, fname) 
% calculates and returns denoised image in voxel space
% FORMAT [Vdcon, Vderr, pD, changef] = get_wdimg(pD, Ic, wdstruct, fname) 
%   
% Inputs (defaults in [square brackets])
% pD         - phido design object
% Ic         - vector of contrast numbers defining statistic image [GUI]
%              if length(Ic)>1 = conjunction. In this case the
%              contrasts should be in orthogonalization order
% wdstruct   - structure with info for wavelet denoising.  
%              Most fields are passed directly to the thresh_calc
%              routine, see that routine for detailed comments.
%              Fields are:
%              'levels' - levels to calulcate / apply  thresholding [](=all)
%              'thlev'  - level at which to apply threshold ['level']             
%              'thcalc' - wavelet denoising type ['stein']
%              'thapp'  - form of wavelet denoising ['linear']
%              'ncalc'  - null hypothesis calculation ['n']
%              'alpha'  - alpha for t etc Bonferroni etc correction [0.05]
%              't2z'    - if not 0, does T to Z transform on T data [0]
%              'write_err' - if not 0, writes std and sort-of t image [1]
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
% $Id: get_wdimg.m,v 1.10 2005/06/21 15:17:42 matthewbrett Exp $
  
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
    'levels', [], ...
    'thlev','level',...
    'thcalc', 'stein', ...
    'thapp', 'linear', ...
    'ncalc', 'n', ...
    'varpoolf',0,...
    'alpha', 0.05,...
    't2z', 1, ...
    'write_err', 1);

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
  if isempty(fname), return, end
end
Qdir = spm_str_manip(fname,'Hv');
fname = [spm_str_manip(fname,'stv'),'.img'];
if ~strcmp(Qdir, '.')
  fprintf('Note: writing image to current directory');
end

% write con and statistic images
%=======================================================================
[pD, Ic, changef] = write_contrasts(pD, Ic);

% get contrasts 
if changef, xCon = get_contrasts(pD); end
xC1  = xCon(Ic);
erdf = error_df(pD);
edf   = [xC1.eidf erdf];

% get contrast image
wave = get_wave(pD);
wvcon = phiw_wvimg(xC1.Vcon,struct('noproc',0), wave);

% get and process error image
VResMS = get_vol_field(pD, 'VResMS');
wverr = phiw_wvimg(VResMS,[], wave);
rmsi = as_matrix(wverr);
rmsi(abs(rmsi)<eps) = NaN;
con_cov = xC1.c'*xX.Bcov*xC1.c;
rmsi = sqrt(rmsi .* con_cov);
wverr = as_matrix(wverr, rmsi);

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
    'descrip',sprintf('Phiwave{%c} - %s',...
		      xC1.STAT,xC1.name));
Vdcon = write_iwtimg(wvcond,Vdcon);
fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

% Write description into text file
write_descrip(wvcond,Vdcon);

% Create error map, if we have saved residuals
VResI = get_vol_field(pD, 'VResI');
if ~isempty(VResI) & wdstruct.write_err
  % Quite a lot of work to do here
  nScan = prod(size(VResI));
  oi = oimgi(wave);
  odim = diff(oi)+1;
  std_img = zeros(odim);
  sum_img = std_img;
    
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
    std_img = std_img + img .^2;
  end
  xX = design_structure(pD);
  std_img = (std_img - (sum_img .^2 / nScan)) / xX.trRV;
  std_img = sqrt(std_img .* con_cov);
  
  % save std image
  efname = fullfile(d_swd, ['std_' fname]);
  Vderr = struct(...
      'fname',  efname,...
      'dim',    [odim,16],...
      'mat',    wave.ovol.mat,...
      'pinfo',  [1,0,0]',...
      'descrip',sprintf('Phiwave{%c} - error:%s',...
			xC1.STAT,xC1.name));
  Vderr = spm_write_vol(Vderr, std_img);

  % save sort-of t image
  con_img = spm_read_vols(Vdcon);
  t_msk = abs(con_img) > eps & abs(std_img) > eps;
  t_img = zeros(size(con_img));
  t_img(t_msk) = con_img(t_msk) ./ std_img(t_msk);
  tfname = fullfile(d_swd, ['t_' fname]);
  Vdt = struct(...
      'fname',  tfname,...
      'dim',    [odim,16],...
      'mat',    wave.ovol.mat,...
      'pinfo',  [1,0,0]',...
      'descrip',sprintf('Phiwave{%c} - t:%s',...
			xC1.STAT,xC1.name));
  Vdt = spm_write_vol(Vdt, t_img);

  fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done');
end
return