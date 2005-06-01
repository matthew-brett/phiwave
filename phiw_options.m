function [phiw, msgstr] = phiw_options(optstr, phiw, cfg_fname)
% options utility routines
% FORMAT [phiw msgstr] = phiw_options(optstr, phiw, cfg_fname)
%
% Input [default]
% optstr            - option string: one of
%                     'load','save','edit','defaults','basedefaults','fill'
%                     ['load']  
% phiw              - phiwave options structure [PHI.OPTIONS]
% cfg_fname         - filename for configuration file [GUI]
% 
% Output
% phiw              - possible modified phiwave structure
% msgstr            - any relevant messages
%
% Matthew Brett 20/10/00,2/6/01
%
% $Id: phiw_options.m,v 1.9 2005/06/01 10:57:22 matthewbrett Exp $
  
if nargin < 1
  optstr = 'load';
end
if nargin < 2
  phiw = [];
end
if nargin < 3
  cfg_fname = '';
end
if isempty(phiw)
  phiw = mars_struct('getifthere', spm('getglobal','PHI'), 'OPTIONS');
end
msgstr = '';

% fields, and descriptions of fields, in phiw options structure
optfields = {'wt','denoise','structural','display','statistics'}; 
optlabs =  {'Wavelet transform','Denoising','Default structural','Image display','Statistics'};

switch lower(optstr)
 
 % --------------------------------------------------
 case 'load'
  if isempty(cfg_fname)
    [fn, fn2] = phiwave('cfgfile');
    if isempty(fn), fn=fn2;end
    [p f e] = fileparts(fn);
    cfg_fname = spm_get([0 1],[f e], 'Configuration file to load',p);
  end
  if ~isempty(cfg_fname)
    tmp = load(cfg_fname);
    if ~isempty(tmp)
      if isfield(tmp, 'phiw')
	phiw = mars_struct('fillafromb', tmp.phiw, phiw);
      end
    end
  end
 
  % --------------------------------------------------
 case 'save'
  if nargin < 3
    [fn, fn2] = phiwave('cfgfile');
    if isempty(fn), fn=fn2;end
    [f p] = uiputfile(fn, 'Configuration file to save');
    cfg_fname = fullfile(p, f);
  end
  if ~isempty(cfg_fname)
    try
      save(cfg_fname, 'phiw');
    catch
      warning(['Error saving config to file ' cfg_fname])
    end
  end
  
  % --------------------------------------------------
 case 'basedefaults'
  % hardcoded defaults

  % scales for wavelet image transform  
  phiw.wt.scales = 4;

  % wavelet 
  phiw.wt.wavelet = phiw_lemarie(2);
  
  % wavelet transformed file prefix
  phiw.wt.wtprefix = 'wv_';
  
  % threshold for statistics mask post wt
  phiw.statistics.maskthresh = 0.05;
  
  % wavelet denoising unit
  phiw.denoise.thlev = 'quadrant';
  
  % wavelet denoising type
  phiw.denoise.thcalc = 'stein';
  
  % form of wavelet denoising
  phiw.denoise.thapp = 'linear';
  
  % null hypothesis calculation
  phiw.denoise.ncalc = 'n';
  
  % alpha for t etc Bonferroni etc correction
  phiw.denoise.alpha = 0.05;
  
    % default structural image for display
  phiw.structural.fname = fullfile(spm('Dir'), 'canonical', ...
				   ['avg152T1' mars_veropts('template_ext')]);
  
  % range for structural (empty means set from image range)
  phiw.structural.range = [];
  
  % name of default activation colormap for display routines
  phiw.display.cmapname = 'flow.lut';
  
  % proportion of displayed color intensity for activation image 
  phiw.display.actprop = 0.5;
  
  % transform for slice display routine
  phiw.display.transform = 'axial';
  
  % default slices to display (mm)
  phiw.display.slices = -60:6:78;

  % --------------------------------------------------
 case 'edit'
  
  % Edit defaults.  See 'basedefaults' option for other defaults
  defarea = cfg_fname;  % third arg is defaults area, if specified
  if isempty(defarea)
    % get defaults area
    [Finter,Fgraph,CmdLine] = spm('FnUIsetup','PhiWave Defaults');
    % fields, and descriptions of fields, in phiw options structure
    optfields = {'wt','denoise','structural','display'}; 
    optlabs =  {'Wavelet transform','Denoising','Default structural',...
		'Image display'};
		
    defarea = char(...
      spm_input('Defaults area', '+1', 'm',{optlabs{:} 'Quit'},...
		{optfields{:} 'quit'},length(optfields)+1));
  end
  
  oldphiw = phiw;
  switch defarea
   case 'quit'
    return
   case 'wt'
    % scales for analysis
    phiw.wt.scales = spm_input('Scales for analysis', '+1', 'e', phiw.wt.scales, ...
				1);
    
    % wavelet transform
    wlabs =  {'Battle-Lemarie', 'Daubechies'};
    wtypes = {'phiw_lemarie', 'phiw_daub'};
    tmp = oldphiw.wt;
    tmp.wavelet = class(tmp.wavelet);
    phiw.wt = getdefs(...
	phiw.wt,...
	tmp,...
	'wavelet',...
	'Wavelet',...
	wtypes,...
	wlabs);
    switch phiw.wt.wavelet
     case 'phiw_lemarie'
      wv = phiw_lemarie;
      d_d = spm_input('Divisor for image width', '+1', 'e', 2);
      wv = dim_div(wv, d_d);
     case 'phiw_daub'
      wv = phiw_daub;
      n_c = spm_input('Number of coefficients', '+1', 'e', 4);
      wv = num_coeffs(wv, n_c);
    end
    phiw.wt.wavelet = wv;

    % wavelet transform prefix
    phiw.wt.wtprefix = spm_input('WT image prefix', '+1', 's', ...
			      phiw.wt.wtprefix);
     
    
     % denoising defaults
   case 'denoise'
    % denoising threshold calculation
    phiw.denoise = getdefs(...
	phiw.denoise,...
	oldphiw.denoise,...
	'thcalc',...
	'Threshold calculation',...
	{'visu','sure','stein','bonf','fdr','hoch'},...
	['MinMax|SURE|Stein|Bonferroni|FDR|Hoch']); ...
	   
    % denoising block level
    phiw.denoise = getdefs(...
	phiw.denoise,...
	oldphiw.denoise,...
	'thlev',...
	'Threshold level',...
	{'image','level','quadrant'},...
	['Image|Level|Quadrant']);
    
	   
    % denoising threshold application
    if strmatch('sure', phiw.denoise.thcalc)
      phiw.denoise.thapp = 'soft';
    else
      vals = {'soft','hard'};
      labs = 'Soft|Hard';
      if strcmp(phiw.denoise.thcalc, 'stein')
	vals = {vals{:},'linear'};
	labs = [labs '|Linear'];
      end
      phiw.denoise = getdefs(...
	  phiw.denoise,...
	  oldphiw.denoise,...
	  'thapp',...
	  'Thresholding method',...
	  vals,...
	  labs);
    end

    % p value thresholding methods
    if any(strcmp(phiw.denoise.thcalc,...
	   {'bonf','hoch','fdr'}))
      
      % denoising null hypothesis calculation
      phiw.denoise = getdefs(...
	  phiw.denoise,...
	  oldphiw.denoise,...
	  'ncalc',...
	  'Estimate of Ho coefficient no',...
	  {'n','pplot'},...
	  ['Raw no|PPlot']);
      
      % alpha for t etc Bonferroni correction
      phiw.denoise.alpha = spm_input('Alpha level', '+1', 'r', ...
				 phiw.denoise.alpha,1,[0 1]);
    else
      phiw.denoise.ncalc = 'n';
    end

    % display stuff - default structural scan
   case 'structural'
    phiw.structural.fname = spm_get(1, mars_veropts('get_img_ext'),...
				    'Default structural image', ...
				    fileparts(phiw.structural.fname));
    
    % intensity range for structural
    [mx mn] = slover('volmaxmin', spm_vol(phiw.structural.fname));
    phiw.structural.range = spm_input('Img range for structural','+1', ...
				      'e', [mn mx], 2);
    
    % display stuff - color overlays
   case 'display'
     % name of colormap for display routines
     cmap = [];
     ypos = spm_input('!NextPos');
     while isempty(cmap)
       cmapname = spm_input('Name of activation colormap', ypos,'s', ...
			    phiw.display.cmapname);
       [cmap str] = slover('getcmap', cmapname);
       if isempty(cmap)
	 disp(str);
       end
     end
     phiw.display.cmapname = cmapname;
     
     % proportion of displayed color intensity for activation image 
     phiw.display.actprop = spm_input('Activation colour intensity', '+1', 'r', ...
			      phiw.display.actprop,1,[0 1]);
     
     phiw.display.transform = lower(spm_input('Image orientation', '+1','b',...
				      ['Axial|Coronal|Sagittal'], [],1));
     ypos = spm_input('!NextPos'); sflg = 0;
     while ~sflg
       sflg=1;
       slstr = spm_input('Slices to display (mm)', ypos, 's', ...
			 sprintf('%0.0f:%0.0f:%0.0f',...
				 min(phiw.display.slices),...
				 mean(diff(phiw.display.slices)),...
				 max(phiw.display.slices)));
       eval(['phiw.display.slices = ' slstr ';'], 'sflg=0;');
     end

     % statistics - not currently used
   case 'statistics'
     phiw.statistics.maskthresh = spm_input('WT mask threshold', '+1', 'r', ...
			      phiw.statistics.maskthresh,1,[0 1]);
     
   otherwise 
    error('Unknown defaults area')
  end

  % Offer a rollback
  if spm_input('Accept these settings', '+1', 'b','Yes|No',[0 1],1)
    phiw = oldphiw;
  end
  
  % --------------------------------------------------
 case 'defaults'                             %-get phiwave defaults
  pwdefs = [];
  msgstr = 'base defaults';
  cfgfile = phiwave('cfgfile');
  if ~isempty(cfgfile);
    tmp = load(cfgfile);
    if isfield(tmp, 'phiw')
      pwdefs = tmp.phiw;
      msgstr = cfgfile;
    else
      warning(...
	  ['File ' cfgfile ' does not contain valid config settings'],...
	  'Did not load phiwave config file');
    end
  end
  phiw = mars_struct('fillafromb', ...
		     pwdefs, phiw_options('basedefaults'));
  
   % --------------------------------------------------
 case 'fill'                             %-fill from template
  phiw = mars_struct('fillafromb', phiw,cfg_fname);
  
 otherwise
  error('Don''t recognize options action string')
end
return


function s = getdefs(s, defval, fieldn, prompt, vals, labels)
% sets field in structure given values, labels, etc
    
if isstruct(defval)
  defval = getfield(defval, fieldn);  
end

if ischar(defval)
  defind = find(strcmp(defval,vals));
else
  defind = find(defval == vals);
end

v = spm_input(prompt, '+1', 'm', labels, vals, defind);
if iscell(v) & ischar(defval)
  v = char(v);
end
  
s = setfield(s,fieldn,v);

return