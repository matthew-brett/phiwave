function [phiwD, connos, changef] = write_contrasts(phiwD, connos, flags) 
% Writes contrast and statistic images
% FORMAT [phiwD, connos] = write_contrasts(phiwD, flags) 
% phiw_write_contrasts(spmmat,connos,xCon,flags,phiw)
% 
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
% 
% Based (very) closely on spm_getSPM from the spm99 distribution
% (spm_getSPM, v2.35 Andrew Holmes, Karl Friston & Jean-Baptiste Poline 00/01/2)
% 
% Matthew Brett 9/10/00  
%
% $Id: write_contrasts.m,v 1.1 2004/11/18 18:35:27 matthewbrett Exp $

if ~is_phiw_estimated(phiwD), error('Need phiwave estimated design'); end
changef = 0;
if nargin < 2
  connos = [];
end

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

% Get SPM structure
SPM = des_struct(phiwD);

% wave file prefix
wvobj = phiw_wvimg(SPM
wvp = 

% map filenames -> vols
if ~isstruct(spmmat.Vbeta)
  spmmat.Vbeta  = ...
      spm_vol([repmat([swd,filesep],length(spmmat.Vbeta),1), ...
	       char(spmmat.Vbeta)]);
end
if ~isstruct(spmmat.VResMS)
  spmmat.VResMS = spm_vol(fullfile(swd,spmmat.VResMS));
end

%-Get mm<->voxel matrices & image dimensions & design from SPM.mat
%-----------------------------------------------------------------------
M     = spmmat.M;
DIM   = spmmat.DIM;
xX    = spmmat.xX;			%-Design definqition structure

%-Load contrast definitions (if needed and available)
%-----------------------------------------------------------------------
if isempty(xCon) & exist(fullfile(swd,'xCon.mat'),'file')
  load(fullfile(swd,'xCon.mat'))
end

%-See if can write to current directory (by trying to resave xCon.mat)
%-----------------------------------------------------------------------
try
  save(fullfile(swd,'xCon.mat'),'xCon')
catch
  wOK = 0;
  str = {'Can''t write to the results directory:',...
	 '(problem saving xCon.mat)',...
	 ['        ',swd],...
	 ' ','-> results restricted to contrasts already computed'};
  spm('alert!',str,mfilename,1);
end

%-Get contrasts if needed (if multivariate there is only one structure)
%-----------------------------------------------------------------------
nVar    = size(spmmat.VY,2);
if nVar > 1 
  connos == 1;
elseif isempty(connos) 
  [connos,xCon] = spm_conman(xX,xCon,statstr,ncons,...
			 '	Select contrasts...','to compute',wOK);
end

if isempty(connos)
  return
end

% get wave transform parameters
if isfield(spmmat.xM, 'wave') % set in modified spm_spm version
  wave = spmmat.xM.wave;
else
  % try to get wave info 
  options = struct('noproc',1);
  wave = phiw_wvimg(spmmat.VY(1),options);
  if isempty(wave)
    error(['No wave info for first image - unlikely to be wavelet' ...
	   ' analysis'])
  end
end

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
  if ~isfield(xCon(i),'eidf') | isempty(xCon(i).eidf)
    [trMV,trMVMV] = spm_SpUtil('trMV',...
			       spm_FcUtil('X1o',xCon(i),xX.xKXs),xX.V);
    xCon(i).eidf  = trMV^2/trMVMV;
  else
    trMV = []; trMVMV = [];
  end

  % make sensible file suffix from contrast name
  fsuff = mars_utils('str2fname', xCon(i).name);
  
  %-Write contrast/ESS images?
  %-------------------------------------------------------------------
  if ~isfield(xCon(i),'Vcon') | isempty(xCon(i).Vcon) | ...
        ~exist(fullfile(swd,xCon(i).Vcon),'file')
        
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
      V     = spmmat.Vbeta(Q);
      for j = 1:length(Q)
	V(j).pinfo(1,:) = V(j).pinfo(1,:)*xCon(i).c(Q(j));
      end
      
      %-Prepare handle for contrast image
      %-----------------------------------------------------------
      xCon(i).Vcon = struct(...
	  'fname',  fullfile(swd,sprintf('%scon_%04d_%s.img',wvp,i,fsuff)),...
	  'dim',    [DIM',16],...
	  'mat',    M,...
	  'pinfo',  [1,0,0]',...
	  'descrip',sprintf('PhiWave contrast - %d: %s',i,xCon(i).name));
      
      %-Write image
      %-----------------------------------------------------------
      fprintf('%s%20s',sprintf('\b')*ones(1,20),'...computing')%-#
      xCon(i).Vcon            = spm_create_image(xCon(i).Vcon);
      xCon(i).Vcon.pinfo(1,1) = spm_add(V,xCon(i).Vcon);
      xCon(i).Vcon            = spm_create_image(xCon(i).Vcon);
            
      fprintf('%s%30s\n',sprintf('\b')*ones(1,30),sprintf(...
	  '...written %s',spm_str_manip(xCon(i).Vcon.fname,'t')))%-#

     case 'F'  %-Implement ESS as sum of squared weighted beta images
      fprintf('\t%-32s: %30s',sprintf('ESS image %2d',i),...
	      '...computing') %-#
      
      %-Residual (in parameter space) forming mtx
      %-----------------------------------------------------------
      h       = spm_FcUtil('Hsqr',xCon(i),xX.xKXs);
      
      %-Prepare handle for ESS image
      %-----------------------------------------------------------
      xCon(i).Vcon = struct(...
	  'fname',  fullfile(swd,sprintf('%sess_%04d_%s.img',wvp,i,fsuff)),...
	  'dim',    [DIM',16],...
	  'mat',    M,...
	  'pinfo',  [1,0,0]',...
	  'descrip',sprintf('PhiWave ESS - contrast %d: %s',i,xCon(i).name));
      
      %-Write image
      %-----------------------------------------------------------
      fprintf('%s',sprintf('\b')*ones(1,30))                   %-#
      xCon(i).Vcon  = spm_create_image(xCon(i).Vcon);
      xCon(i).Vcon  = spm_resss(spmmat.Vbeta,xCon(i).Vcon,h);
      xCon(i).Vcon  = spm_create_image(xCon(i).Vcon);
      
     otherwise
      %---------------------------------------------------------------
      error(['unknown STAT "',xCon(i).STAT,'"'])
      
    end % (switch(xCon...)
    
    % Write wave info for file
    putwave(xCon(i).Vcon.fname,wave);
    
  elseif isfield(xCon(i),'Vcon') & ~isempty(xCon(i).Vcon) & ...
        exist(fullfile(swd,xCon(i).Vcon),'file')  
 
    %-Already got contrast/ESS image - remap it w/ full pathname
    %---------------------------------------------------------------
    xCon(i).Vcon = spm_vol(fullfile(swd,xCon(i).Vcon));
    
  end % (if isfield...)

  spm_progress_bar('Set',100*(2*ii-1)/(2*length(I)+2))             %-#
  
  %-Write statistic image(s)
  %-------------------------------------------------------------------
  if ~any(flags=='c') & (~isfield(xCon(i),'Vspm') | isempty(xCon(i).Vspm) | ...
        ~exist(fullfile(swd,xCon(i).Vspm),'file'))
    
    % Read Residual mean squared image if necessary
    if isempty(rmsi)
      fprintf('\t%-32s: %30s','ResMS file...','...done');
      rmsi = spm_read_vols(spmmat.VResMS);
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
      
      Z   = spm_read_vols(xCon(i).Vcon)./...
	    (sqrt(rmsi * (xCon(i).c'*xX.Bcov*xCon(i).c) ));
      
      str = sprintf('[%.2g]',xX.erdf);
      
     case 'F'                                  %-Compute {F} image
      
      if isempty(trMV)
	trMV = spm_SpUtil('trMV',spm_FcUtil('X1o',xCon(i),xX.xKXs),xX.V);
      end
      Z =(spm_read_vols(xCon(i).Vcon)/trMV)./rmsi;
      
      str = sprintf('[%.2g,%.2g]',xCon(i).eidf,xX.erdf);
            
     otherwise
      %---------------------------------------------------------------
      error(['unknown STAT "',xCon(i).STAT,'"'])
    end
        
    %-Write full statistic image
    %---------------------------------------------------------------
    fprintf('%s%30s',sprintf('\b')*ones(1,30),'...writing')      %-#
    xCon(i).Vspm = struct(...
	'fname',  fullfile(swd,sprintf('%s%c_%04d_%s.img',wvp,xCon(i).STAT,i,fsuff)),...
	'dim',    [DIM',16],...
	'mat',    M,...
	'pinfo',  [1,0,0]',...
	'descrip',sprintf('PhiWave{%c_%s} - contrast %d: %s',...
			  xCon(i).STAT,str,i,xCon(i).name));
        
    xCon(i).Vspm       = spm_write_vol(xCon(i).Vspm,Z);
    
    % Write wave part of mat file
    putwave(xCon(i).Vcon.fname,wave);
    
    fprintf('%s%30s\n',sprintf('\b')*ones(1,30),sprintf(...
	'...written %s',spm_str_manip(xCon(i).Vspm.fname,'t')))  %-#
    
  elseif isfield(xCon(i),'Vspm') & ~isempty(xCon(i).Vspm) & ...
        exist(fullfile(swd,xCon(i).Vspm),'file')  
    %-Already got statistic image - remap it w/ full pathname
    %---------------------------------------------------------------
    xCon(i).Vspm = spm_vol(fullfile(swd,xCon(i).Vspm));
    
  end % (if isfield...)
  
  spm_progress_bar('Set',100*(2*ii-0)/(2*length(I)+2))             %-#

end % (for ii = 1:length(I))

spm_progress_bar('Set',100)                                          %-#

% xCon for return has filenames
rxCon = xCon;

% Read Residual mean squared image if necessary
if nargout > 4 & isempty(rmsi)
  fprintf('\t%-32s: %30s','ResMS file...','...done');
  rmsi = spm_read_vols(spmmat.VResMS);
  fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#
  rmsi(abs(rmsi)<eps) = NaN;
end

%-Save contrast structure (if wOK), with relative pathnames to image files
%=======================================================================
if wOK
  for i = I;
    if ~isempty(xCon(i).Vcon)
      xCon(i).Vcon = spm_str_manip(xCon(i).Vcon.fname,'t');
    end
    if ~isempty(xCon(i).Vspm)
      xCon(i).Vspm = spm_str_manip(xCon(i).Vspm.fname,'t');
    end
  end
  save(fullfile(swd,'xCon.mat'),'xCon')
  fprintf('\t%-32s: %30s\n','contrast structure','...saved to xCon.mat')%-#
end

spm_progress_bar('Clear')                                          %-#

return

% thank you