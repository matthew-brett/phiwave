function [phiwD, connos, changef, rmsi] = write_contrasts(phiwD, connos, flags) 
% Writes contrast and statistic images
% FORMAT [phiwD, connos, changef, rmsi] = write_contrasts(phiwD, connos, flags) 
% 
% Inputs
% phiwD      - phido design object
% connos     - vector of contrasts to write (fetched by GUI if empty)
% flags      - flags containing none or more of
%              n - forbids new contrasts being entered (where connos=[])
%              t - allow t contrasts only (where connos=[])
%              f - allow f contrasts only (where connos=[])
%              s - allows a Single contrast only (where connos=[])
%              c - don't write statistic images (i.e. con images only)
% 
% Returns
% phiwD      - modified design object
% connos     - vector of contrast numbers (as input, or from GUI)
% changef    - set to 1 is phiwD object has changed
% rmsi       - residual mean squared image as 3D matrix
%
% Based (very) closely on spm_getSPM from the spm99 distribution
% (spm_getSPM, v2.35 Andrew Holmes, Karl Friston & Jean-Baptiste Poline
% 00/01/2)  
% 
% Matthew Brett 9/10/00  
%
% $Id: write_contrasts.m,v 1.4 2005/04/20 20:22:37 matthewbrett Exp $

if ~is_phiw_estimated(phiwD), error('Need phiwave estimated design'); end
changef = 0;
if nargin < 2
  connos = [];
end
if nargin < 3
  flags = '';
end
rmsi = [];

% flags decoding
if isempty(flags), flags = ' '; end
wOK = ~any(flags == 'n'); % forbid new contrasts
if any(flags=='t')    % only F, only t flags for contrast selection
  statstr = 'T';
elseif any(flags=='f')
  statstr = 'F';
else
  statstr = 'T|F';
end
if any(flags == 's')  % only one contrast at a time
  ncons = 1;
else
  ncons = Inf;
end

% get needed stuff from design
Vbeta  = get_vol_field(phiwD, 'Vbeta');
VResMS = get_vol_field(phiwD, 'VResMS');
VY  = get_images(phiwD);
xM  = masking_struct(phiwD);
erdf = error_df(phiwD);
M    = VY(1).mat;
DIM  = VY(1).dim(1:3);
xX   = design_structure(phiwD);
swd  = swd(phiwD);

%-See if can write to current directory 
%-----------------------------------------------------------------------
wOK = swd_writable(phiwD);
if ~wOK
  str = {'Can''t write to the results directory:',...
	 ['        ',swd],...
	 ' ','-> results restricted to contrasts already computed'};
  spm('alert!',str,mfilename,1);
end

%-Get contrasts if needed (if multivariate there is only one structure)
%-----------------------------------------------------------------------
nVar    = size(VY,2);
if nVar > 1 
  connos == 1;
elseif isempty(connos) 
  [connos, phiwD, changef] = ui_get_contrasts(phiwD, statstr, ncons,...
			 '	Select contrasts...','to compute', wOK);
end

if isempty(connos)
  return
end
xCon = get_contrasts(phiwD);

% get wave transform parameters
wave = get_wave(phiwD);
if isempty(wave)
  error(['No wave info for first image - unlikely to be wavelet' ...
	 ' analysis'])
end
wvp = getfield(wtinfo(wave), 'wtprefix');

%-Compute & store contrast parameters, contrast/ESS images, & stat images
%=======================================================================
spm('Pointer','Watch')
spm_progress_bar('Init',100,'computing...')                          %-#
nPar   = size(xX.X,2);
I      = unique(connos);
for ii = 1:length(I)
  
  i  = I(ii);

  % Check exists
  if i > length(xCon)
    warning(['Contrast ' num2str(i) ' does not exist']);
    break;
  end
  
  %-Canonicalise contrast structure with required fields
  %-------------------------------------------------------------------
  eidf = mars_struct('getifthere', xCon(i), 'eidf');
  if isempty(eidf)
    X1o           = spm_FcUtil('X1o',xCon(ic),SPM.xX.xKXs);
    [trMV,trMVMV] = spm_SpUtil('trMV',X1o,SPM.xX.V);
    xCon(ic).eidf = trMV^2/trMVMV;
  else
    trMV = []; trMVMV = [];
  end

  % make sensible file suffix from contrast name
  fsuff = mars_utils('str2fname', xCon(i).name);
  
  %-Write contrast/ESS images?
  %-------------------------------------------------------------------
  Vcon = full_vol(phiwD, ...
		  mars_struct('getifthere', xCon(i), 'Vcon'));
  if isempty(Vcon.dim)

    % We're going to change the contrast structure
    changef = 1;
    
    %-Bomb out (nicely) if can't write to results directory
    %---------------------------------------------------------------
    if ~wOK, spm('alert*',{	'Can''t write to the results directory:',...
		    ['        ',swd],' ','=> can''t compute new contrasts'},...
		 mfilename,sqrt(-1));
      spm('Pointer','Arrow')
      error('can''t write contrast image')
    end
        
    switch(xCon(i).STAT)
      
     case 'T'       %-Implement contrast as sum of scaled beta images
      		 
      fprintf('\t%-32s: %-10s%20s',sprintf('contrast image %2d',i),...
	      '(spm_add)','...initialising') %-#
      
      Q     = find(abs(xCon(i).c) > 0);
      V     = Vbeta(Q);
      for j = 1:length(Q)
	V(j).pinfo(1,:) = V(j).pinfo(1,:)*xCon(i).c(Q(j));
      end
      
      %-Prepare handle for contrast image
      %-----------------------------------------------------------
      Vcon = struct(...
	  'fname',  fullfile(swd,sprintf('%scon_%04d_%s.img',wvp,i,fsuff)),...
	  'dim',    [DIM,16],...
	  'mat',    M,...
	  'pinfo',  [1,0,0]',...
	  'descrip',sprintf('PhiWave contrast - %d: %s',i,xCon(i).name));
      
      %-Write image
      %-----------------------------------------------------------
      fprintf('%s%20s',sprintf('\b')*ones(1,20),'...computing')%-#
      Vcon            = spm_create_image(Vcon);
      Vcon.pinfo(1,1) = spm_add(V, Vcon);
      Vcon            = spm_create_image(Vcon);
            
      fprintf('%s%30s\n',sprintf('\b')*ones(1,30),sprintf(...
	  '...written %s',spm_str_manip(Vcon.fname,'t')))%-#
     case 'F'  %-Implement ESS as sum of squared weighted beta images
      fprintf('\t%-32s: %30s',sprintf('ESS image %2d',i),...
	      '...computing') %-#
      
      %-Residual (in parameter space) forming mtx
      %-----------------------------------------------------------
      h       = spm_FcUtil('Hsqr',xCon(i),xX.xKXs);
      
      %-Prepare handle for ESS image
      %-----------------------------------------------------------
      Vcon = struct(...
	  'fname',  fullfile(swd,sprintf('%sess_%04d_%s.img',wvp,i,fsuff)),...
	  'dim',    [DIM 16],...
	  'mat',    M,...
	  'pinfo',  [1,0,0]',...
	  'descrip',sprintf('PhiWave ESS - contrast %d: %s',i,xCon(i).name));
      
      %-Write image
      %-----------------------------------------------------------
      fprintf('%s',sprintf('\b')*ones(1,30))                   %-#
      Vcon  = spm_create_image(xCon(i).Vcon);
      Vcon  = spm_resss(Vbeta,xCon(i).Vcon,h);
      Vcon  = spm_create_image(xCon(i).Vcon);
      
     otherwise
      %---------------------------------------------------------------
      error(['unknown STAT "',xCon(i).STAT,'"'])
      
    end % (switch(xCon...)
    
    % Put into structure array
    xCon(i).Vcon = design_vol(phiwD, Vcon);

    % Write wave info for file
    putwave(Vcon.fname,wave);
        
  end % (if isempty...)

  spm_progress_bar('Set',100*(2*ii-1)/(2*length(I)+2))             %-#
  
  %-Write statistic image(s)
  %-------------------------------------------------------------------
  Vspm = full_vol(phiwD, ...
		  mars_struct('getifthere', xCon(i), 'Vspm'));
  if ~any(flags=='c') & isempty(Vspm.dim)
    
    % We're going to change the contrast structure
    changef = 1;
    
    % Read Residual mean squared image if necessary
    if isempty(rmsi)
      fprintf('\t%-32s: %30s','ResMS file...','...done');
      rmsi = spm_read_vols(VResMS);
      fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#
      rmsi(abs(rmsi)<eps) = NaN;
    end

    %-Bomb out (nicely) if can't write to results directory
    %---------------------------------------------------------------
    if ~wOK, spm('alert*',{	'Can''t write to the results directory:',...
		    ['        ',swd],' ','=> can''t compute new contrasts'},...
		 mfilename,sqrt(-1));
      spm('Pointer','Arrow')
      error('can''t write PhiWave image')
    end
    
    fprintf('\t%-32s: %30s',sprintf('phiw{%c} image %2d',xCon(i).STAT,i),...
	    '...computing')  %-#
    
    switch(xCon(i).STAT)
     case 'T'                                  %-Compute {t} image
      
      Z   = spm_read_vols(Vcon)./...
	    (sqrt(rmsi * (xCon(i).c'*xX.Bcov*xCon(i).c) ));
      
      str = sprintf('[%.2g]',erdf);
      
     case 'F'                                  %-Compute {F} image
      
      if isempty(trMV)
	trMV = spm_SpUtil('trMV',spm_FcUtil('X1o',xCon(i),xX.xKXs),xX.V);
      end
      Z =(spm_read_vols(Vcon)/trMV)./rmsi;
      
      str = sprintf('[%.2g,%.2g]',xCon(i).eidf,erdf);
            
     otherwise
      %---------------------------------------------------------------
      error(['unknown STAT "',xCon(i).STAT,'"'])
    end
        
    %-Write full statistic image
    %---------------------------------------------------------------
    fprintf('%s%30s',sprintf('\b')*ones(1,30),'...writing')      %-#
    Vspm = struct(...
	'fname',  fullfile(swd,sprintf('%sphiw%c_%04d_%s.img',wvp,xCon(i).STAT,i,fsuff)),...
	'dim',    [DIM 16],...
	'mat',    M,...
	'pinfo',  [1,0,0]',...
	'descrip',sprintf('PhiWave{%c_%s} - contrast %d: %s',...
			  xCon(i).STAT,str,i,xCon(i).name));
        
    Vspm       = spm_write_vol(Vspm,Z);
    
    % Write wave part of mat file
    putwave(Vspm.fname,wave);
    
    fprintf('%s%30s\n',sprintf('\b')*ones(1,30),sprintf(...
	'...written %s',spm_str_manip(Vspm.fname,'t')))  %-#
        
  end % (if ~ flags 'c' & isemptu...)
  
  % Put into structure array
  xCon(i).Vspm = design_vol(phiwD, Vspm);

  % Write wave info for file
  putwave(Vspm.fname,wave);
        
  spm_progress_bar('Set',100*(2*ii-0)/(2*length(I)+2))             %-#

end % (for ii = 1:length(I))

spm_progress_bar('Set',100)                                          %-#

% Read Residual mean squared image if necessary
if nargout > 4 & isempty(rmsi)
  fprintf('\t%-32s: %30s','ResMS file...','...done');
  rmsi = spm_read_vols(VResMS);
  fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#
  rmsi(abs(rmsi)<eps) = NaN;
end

%- put contrasts back into design
%=======================================================================
phiwD = set_contrasts(phiwD, xCon);

spm_progress_bar('Clear')                                          %-#

return

% thank you, really