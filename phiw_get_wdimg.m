function [Vdcon, Vderr] = phiw_get_wdimg(varargin) 
% calculates and returns denoised image in voxel space
% FORMAT [Vdcon Vderr] = phiw_get_wdimg(spmmat,xCon,Ic,wdstruct,fname)
%   
% Inputs (defaults in [square brackets])
% spmmat     - name of SPM.mat file, or structure from SPM.mat file
% xCon       - SPM contrast structure [loaded from file]
% Ic         - vector of contrast numbers defining statistic image [GUI]
%              if length(Ic)>1 = conjunction. In this case the
%              contrasts should be in orthogonalization order
% wdstruct   - structure with info for wavelet denoising [Bonf etc denoising]
% fname      - filename for denoised image [via GUI]
%
% Returns
% Vdcon      - spm vol struct for denoised image
% Vderr      - spm vol struct for error image
%
% Based on spm_getSPM from the spm99 distribution
% (spm_getSPM, v2.35 Andrew Holmes, Karl Friston & Jean-Baptiste Poline 00/01/2)
%
% Matthew Brett, Federico Turkheimer, 9/10/00
% error maps added 19/11/01 - RP
%
% $Id: phiw_get_wdimg.m,v 1.1 2004/06/25 15:20:40 matthewbrett Exp $
  
% set unpassed args to empty
[spmmat, xCon, Ic, wdstruct, fname] = argfill(varargin);

% get SPM.mat file as struct
[spmmat swd] = phiwave('get_spmmat', spmmat);

% get PHIWAVE values if not passed
if isempty(wdstruct)
  phiw = spm('getglobal', 'PHIWAVE');
  wdstruct = phiw.denoise;
end

%-Get Stats data from SPM.mat
%-----------------------------------------------------------------------
xX     = spmmat.xX;			%-Design definition structure

%-Get/Compute mm<->voxel matrices & image dimensions from SPM.mat
%-----------------------------------------------------------------------
 M     = spmmat.M;
iM     = inv(M);
DIM    = spmmat.DIM;

%-Contrast definitions
%=======================================================================

%-Load contrast definitions (if available)
%-----------------------------------------------------------------------
if isempty(xCon)
  if exist(fullfile(swd,'xCon.mat'),'file')
    load(fullfile(swd,'xCon.mat'))
  end
end

%-See if can write to current directory (by trying to resave xCon.mat)
%-----------------------------------------------------------------------
wOK = 1;
try
  save(fullfile(swd,'xCon.mat'),'xCon')
catch
  wOK = 0;
  str = {	'Can''t write to the results directory:',...
        	'(problem saving xCon.mat)',...
		['        ',swd],...
		' ','-> results restricted to contrasts already computed'};
  spm('alert!',str,mfilename,1);
end

%=======================================================================
% - C O N T R A S T S 
%=======================================================================

%-Get contrasts (if multivariate there is only one structure)
%-----------------------------------------------------------------------
nVar    = size(spmmat.VY,2);

% flag that orthogonalization order is required
orthf = 0;
if nVar > 1
  Ic = 1;
else
  if isempty(Ic)
    % only single t contrast allowed for the moment
    [Ic,xCon] = spm_conman(xX,xCon,'T',1,...
			   '	Select contrast...','',wOK);
    orthf = 1; 
  end
end

%-Enforce orthogonality of multiple contrasts for conjunction
% (Orthogonality within subspace spanned by contrasts)
%-----------------------------------------------------------------------
% (Don't want to ask orthogonalisation order if not needed.)
if length(Ic) > 1 & ~spm_FcUtil('|_?',xCon(Ic), xX.xKXs)

  if orthf
    %-Get orthogonalisation order from user
    Ic = spm_input('orthogonlization order','+1','p',Ic,Ic);
  end
  
  %-Successively orthogonalise
  %-------------------------------------------------------------------
  i = 1; while(i < length(Ic)), i = i + 1;
    %-NB: This loop is peculiarly controlled to account for the
    %     possibility that Ic may shrink if some contrasts diasppear
    %     on orthogonalisation (i.e. if there are colinearities)
    
    %-Orthogonalise (subspace spanned by) contrast i wirit previous
    %---------------------------------------------------------------
    oxCon = spm_FcUtil('|_',xCon(Ic(i)), xX.xKXs, xCon(Ic(1:i-1)));
    
    %-See if this orthogonalised contrast has already been entered
    % or is colinear with a previous one. Define a new contrast if
    % neither is the case.
    %---------------------------------------------------------------
    d = spm_FcUtil('In',oxCon,xX.xKXs,xCon);
    
    if spm_FcUtil('0|[]',oxCon,xX.xKXs)
	    %-Contrast was colinear with a previous one - drop it
	    %-----------------------------------------------------------
	    Ic(i)    = [];
	    i        = i - 1;
    elseif any(d)
      %-Contrast unchanged or already defined - note index
      %-----------------------------------------------------------
      Ic(i)    = min(d);
    else
      %-Define orthogonalised contrast as new contrast
      %-----------------------------------------------------------
      oxCon.name = [xCon(Ic(i)).name,' (orthogonalized w.r.t {',...
		    sprintf('%d,',Ic(1:i-2)), sprintf('%d})',Ic(i-1))];
      xCon  = [xCon, oxCon];
      Ic(i) = length(xCon); 
    end

  end % while...
end % if length(Ic)...

%-Save contrast structure (if wOK) - ensures new contrasts are saved
%-----------------------------------------------------------------------
if wOK, save(fullfile(swd,'xCon.mat'),'xCon'), end

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
		    ['phiw_' phiwave('str2fname',str)]);
end
Qdir = spm_str_manip(fname,'Hv');
fname = [spm_str_manip(fname,'stv'),'.img'];
if ~strcmp(Qdir, '.')
  fprintf('Note: writing image to current directory');
end

% write con and statistic images
%=======================================================================
[xCon, wave, Ic, spmmat, rmsi] = phiw_write_contrasts(spmmat,Ic,xCon);

% stuff omitted here for conjunctions
edf   = [xCon(Ic(1)).eidf xX.erdf];

% get contrast and error image
wvcon = phiw_wvimg(xCon(Ic(1)).Vcon,struct('noproc',0),wave);
wverr = phiw_wvimg(spmmat.VResMS,struct('noproc',1),wave);
wverr.img = sqrt(rmsi.*(xCon(Ic(1)).c'*spmmat.xX.Bcov*xCon(Ic(1)).c));

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