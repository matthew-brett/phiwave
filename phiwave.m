function varargout=phiwave(varargin) 
% Startup, callback and utility routine for Phiwave
%
% Phiwave: Functional image wavelet analysis 
%
% Phiwave (the collection of files listed by Contents.m) is copyright under
% the GNU general public license.  Please see phiw_licence.man for details.
% 
% Phiwave written by 
% John Aston, Matthew Brett, Rainer Hinz and Federico Turkheimer
%
% Data structures, programming style and portions of the code rely heavily
% on SPM (http://www.fil.ion.ucl.ac.uk/spm), which is also released
% under the GNU public licence.  Many thanks the SPM authors:
% (John Ashburner, Karl Friston, Andrew Holmes, Jean-Baptiste Poline et al).
%
% $Id: phiwave.m,v 1.16 2005/06/21 14:57:20 matthewbrett Exp $

% Programmer's help
% -----------------
% For a list of the functions implemented here, try
% grep "^case " phiwave.m
  
% Phiwave version
PWver = '3.2';  % Third sourceforge release; alpha

% Required MarsBaR version
MBver = '0.38.1';

% Various working variables in global variable structure
global PHI;

%-Format arguments
%-----------------------------------------------------------------------
if nargin == 0, Action='Startup'; else, Action = varargin{1}; end

%=======================================================================
switch lower(Action), case 'startup'                     %-Start phiwave
%=======================================================================

%-Turn on warning messages for debugging
warning backtrace

% splash screen once per session
splashf = ~phiwave('is_started');

% promote spm directory to top of path, read defaults
phiwave('on');

%-Open startup window, set window defaults
%-----------------------------------------------------------------------
S = get(0,'ScreenSize');
if all(S==1), error('Can''t open any graphics windows...'), end
PF = spm_platform('fonts');

% Splash screen
%------------------------------------------
if splashf
  phiwave('splash');
end

%-Draw phiwave window
%-----------------------------------------------------------------------
Fmenu = phiwave('CreateMenuWin','off');

%-Reveal windows
%-----------------------------------------------------------------------
set([Fmenu],'Visible','on')

%=======================================================================
case 'on'                                           %-Initialise Phiwave
%=======================================================================

% check path for SPM 
if isempty(which('spm'))
  error('SPM does not appear to be on the path')
end

% check path for MarsBaR
if isempty(which('marsbar'))
  marsbar_path = fullfile(spm('dir'), 'toolbox', 'marsbar');
  if exist(marsbar_path, 'dir')
    addpath(marsbar_path);
  else
    error('Cannot find MarsBaR - MarsBaR should be on your matlab path');
  end
end

% check MarsBaR version
badv = ~strcmp(marsbar('ver'), MBver); % to allow 0.38.1 through
if badv
  try
    badv = mars_utils('version_less_than', marsbar('ver'), MBver); 
  end
end
if badv, error(['Need at least MarsBaR version ' MBver]); end

% start MarsBaR
marsbar('on');

% promote Phiwave analysis directories
pwpath = fileparts(which('phiwave.m'));
PHI.ADDPATHS = {fullfile(pwpath, 'uvi_wave')};
addpath(PHI.ADDPATHS{:}, '-begin');
fprintf('Phiwave analysis functions prepended to path\n');

% check SPM defaults are loaded
mars_veropts('defaults');

% set up the ARMOIRE stuff
% see marmoire help for details
if isfield(PHI, 'ARMOIRE')
  o = PHI.ARMOIRE; 
else
  o = marmoire;
end

spm_design_filter = mars_veropts('design_filter_spec');
filter_specs  = {spm_design_filter,...
		 {'*phiw_spm.mat', 'Phiwave results (*phiw_spm.mat)'}};
o = add_if_absent(o, 'def_design', ...
		  struct('default_file_name', 'SPMcfg.mat',...	  
			 'filter_spec', {filter_specs{1}},...
			 'title', 'Default design',...
			 'set_action','phiw_arm_call(''set_design'',o,item,old_o)'));
o = add_if_absent(o, 'est_design',...
		  struct('default_file_name', 'untitled_phiw_spm.mat',...
			 'filter_spec', {filter_specs{2}},...
			 'title', 'Phiwave estimated design',...
			 'set_action', 'phiw_arm_call(''set_results'',o,item,old_o)'));
PHI.ARMOIRE = o;

% and workspace
if ~isfield(PHI, 'WORKSPACE'), PHI.WORKSPACE = []; end

% read any necessary defaults
if ~mars_struct('isthere', PHI, 'OPTIONS')
  loadf = 1;
  PHI.OPTIONS = [];
else
  loadf = 0;
end
[pwdefs sourcestr] = phiw_options('Defaults');
PHI.OPTIONS = phiw_options('fill', PHI.OPTIONS, pwdefs);
if loadf
  fprintf('Loaded Phiwave defaults from %s\n',sourcestr);
end

%=======================================================================
case 'off'                                              %-Unload Phiwave 
%=======================================================================
% res = phiwave('Off')
%-----------------------------------------------------------------------
varargout = {0};

% leave if no signs of phiwave
if ~phiwave('is_started'), return, end

% save outstanding information
btn = phiw_arm('save_ui', 'all', struct('ync', 1, 'no_no_save', 1));
if btn == -1, varargout = {-1}; return, end % cancel

% remove phiwave added directories, unstart marsbar
rmpath(PHI.ADDPATHS{:});
marsbar('off');
fprintf('Phiwave analysis functions removed from path\n');

%=======================================================================
case 'quit'                                        %-Quit Phiwave window
%=======================================================================
% phiwave('Quit')
%-----------------------------------------------------------------------

% do path stuff, save any pending changes
if phiwave('off') == -1, return, end % check for cancel

% leave if no signs of PHIWAVE
if ~phiwave('is_started'), return, end

%-Close any existing 'Phiwave' 'Tag'ged windows
delete(spm_figure('FindWin','Phiwave'));
fprintf('Arrivederci...\n\n');

%=======================================================================
case 'is_started'        %-returns 1 if Phiwave GUI has been initialized
%=======================================================================
% tf  = phiwave('is_started')
varargout = {~isempty(PHI)};

%=======================================================================
case 'cfgfile'                                  %-finds Phiwave cfg file
%=======================================================================
% cfgfn  = phiwave('cfgfile')
cfgfile = 'phiwavecfg.mat';
varargout = {which(cfgfile), cfgfile}; 

%=======================================================================
case 'createmenuwin'                          %-Draw Phiwave menu window
%=======================================================================
% Fmenu = phiwave('CreateMenuWin',Vis)
if nargin<2, Vis='on'; else, Vis=varargin{2}; end

%-Close any existing 'Phiwave' 'Tag'ged windows
delete(spm_figure('FindWin','Phiwave'))

% Version etc info
[PWver,PWc] = phiwave('Ver');

%-Get size and scalings and create Menu window
%-----------------------------------------------------------------------
WS   = spm('WinScale');				%-Window scaling factors
FS   = spm('FontSizes');			%-Scaled font sizes
PF   = spm_platform('fonts');			%-Font names (for this platform)
Rect = [50 600 300 275];           	%-Raw size menu window rectangle
bno = 4; bgno = bno+1;
bgapr = 0.25;
bh = Rect(4) / (bno + bgno*bgapr);      % Button height
gh = bh * bgapr;                        % Button gap
by = fliplr(cumsum([0 ones(1, bno-1)*(bh+gh)])+gh);
bx = Rect(3)*0.1;
bw = Rect(3)*0.8;
Fmenu = figure('IntegerHandle','off',...
	'Name',sprintf('%s',PWc),...
	'NumberTitle','off',...
	'Tag','Phiwave',...
	'Position',Rect.*WS,...
	'Resize','off',...
	'Color',[1 1 1]*.8,...
	'UserData',struct('PWver',PWver,'PWc',PWc),...
	'MenuBar','none',...
	'DefaultTextFontName',PF.helvetica,...
	'DefaultTextFontSize',FS(12),...
	'DefaultUicontrolFontName',PF.helvetica,...
	'DefaultUicontrolFontSize',FS(12),...
	'DefaultUicontrolInterruptible','on',...
	'Renderer','painters',...
	'Visible','off');

%-Objects with Callbacks - main Phiwave routines
%=======================================================================

% Design menu
fw_st = 'struct(''force'', 1, ''warn_empty'', 1)';
funcs = {...
    'phiwave(''make_design'', ''pet'');',...
    'phiwave(''make_design'', ''fmri'');',...
    'phiwave(''make_design'', ''basic'');',...
    'phiwave(''design_report'')',...
    'phiwave(''add_images'')',...
    'phiwave(''edit_filter'')',...
    'phiwave(''check_images'')',...
    'phiwave(''list_images'')',...
    'phiwave(''ana_cd'')',...
    'phiwave(''ana_desmooth'')',...
    'phiwave(''explicit_mask'')',...
    'phiwave(''def_from_est'')',...
    'phiwave(''set_def'');',...
    ['phiw_arm(''save_ui'', ''def_design'', ' fw_st ');'],...
    'phiw_arm(''show_summary'', ''def_design'')'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Design...'...
		    '|PET models',...
		    '|FMRI models',...
		    '|Basic models',...
		    '|Explore',...
		    '|Add images to FMRI design',...
		    '|Add/edit filter for FMRI design',...	
		    '|Check image names in design',...
		    '|List image names to console',...
		    '|Change design path to images',...
		    '|Convert to unsmoothed',...
		    '|Set explicit mask for design',...
		    '|Set design from estimated',...
		    '|Set design from file',...
		    '|Save design to file',...
		    '|Show default design summary'],...
	  'Position',[bx by(1) bw bh].*WS,...
	  'ToolTipString','Set/specify design...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% results menu
funcs = {...
    'phiwave(''estimate'');',...
    'phiwave(''merge_contrasts'');',...
    'phiwave(''add_trial_f'');',...
    'phiwave(''set_defcon'');',...
    'phiwave(''writecons'')',...
    'phiwave(''denoisecon'')',...
    'phiw_display(''display'', ''slices'')',...
    'phiw_display(''display'', ''orth'')',...
    'phiwave(''set_results'');',...
    ['phiw_arm(''save_ui'', ''est_design'', ' fw_st ');'],...
    'phiw_arm(''show_summary'', ''est_design'')'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Results...'...
		    '|Estimate results',...
		    '|Import contrasts',...
		    '|Add trial-specific F',...
		    '|Default contrast...',...
		    '|Write contrast', ...
		    '|Specify/denoise comparison' ...
		    '|Display slices',...
		    '|Display sections',...
		    '|Set results from file',...
		    '|Save results to file',...
		    '|Show estimated design summary'],...
	  'Position',[bx by(2) bw bh].*WS,...
	  'ToolTipString','Write/display contrasts...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

funcs = {'global PHI; PHI.OPTIONS=phiw_options(''load'');',...
	 'phiw_options(''save'');',...
	 'global PHI; PHI.OPTIONS=phiw_options(''edit'');',...
	 ['global PHI; [PHI.OPTIONS str]=phiw_options(''defaults'');' ...
	  ' fprintf(''Defaults loaded from %s\n'', str)']};
	 
uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Options...'...
		  '|Load options|Save options|Edit options|Restore defaults'],...
	  'Position',[bx by(3) bw bh].*WS,...
	  'ToolTipString','Load/save/edit Phiwave options',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

% quit button
uicontrol(Fmenu,'String','Quit',...
	  'Position',[bx by(bno) bw bh].*WS,...
	  'ToolTipString','exit Phiwave',...
	  'ForeGroundColor','r',...
	  'Interruptible','off',...
	  'CallBack','phiwave(''Quit'')');

% Set quit action if Phiwave window is closed
%-----------------------------------------------------------------------
set(Fmenu,'CloseRequestFcn','phiwave(''Quit'')')
set(Fmenu,'Visible',Vis)

varargout = {Fmenu};

%=======================================================================
case {'ver', 'version'}                         %-Return Phiwave version
%=======================================================================
% [v [,banner]] = phiwave('Ver')
%-----------------------------------------------------------------------
varargout = {PWver, 'Phiwave - wavelet analysis toolbox'};

%=======================================================================
case 'splash'                                       %-show splash screen
%=======================================================================
% phiwave('splash')
%-----------------------------------------------------------------------
% Shows splash screen  
WS   = spm('WinScale');		%-Window scaling factors
[X,map] = imread('phiwave.jpg');
aspct = size(X,1) / size(X,2);
ww = 400;
srect = [200 300 ww ww*aspct] .* WS;   %-Scaled size splash rectangle
h = figure('visible','off',...
	   'menubar','none',...
	   'numbertitle','off',...
	   'name','Welcome to Phiwave',...
	   'pos',srect);
im = image(X);
colormap(map);
ax = get(im, 'Parent');
axis off;
axis image;
axis tight;
set(ax,'plotboxaspectratiomode','manual',...
       'unit','pixels',...
       'pos',[0 0 srect(3:4)]);
set(h,'visible','on');
pause(3);
close(h);
 
%=======================================================================
case 'make_design'                       %-runs design creation routines
%=======================================================================
% phiwave('make_design', des_type)
%-----------------------------------------------------------------------
if nargin < 2
  des_type = 'basic';
else
  des_type = varargin{2};
end
if sf_prev_save('def_design') == -1, return, end
D = ui_build(mars_veropts('default_design'), des_type);
phiw_arm('set', 'def_design', D);
phiwave('design_report');

%=======================================================================
case 'list_images'                     %-lists image files in SPM design
%=======================================================================
% phiwave('list_images')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end;
if has_images(phiwD)
  P = image_names(phiwD);
  strvcat(P{:})
else
  disp('Design does not contain images');
end

%=======================================================================
case 'check_images'                   %-checks image files in SPM design
%=======================================================================
% phiwave('check_images')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end;
if ~has_images(phiwD)
  disp('Design does not contain images');
  return
end

P = image_names(phiwD);
P = strvcat(P{:});
ok_f = 1;
for i = 1:size(P, 1)
  fname = deblank(P(i,:));
  if ~exist(fname, 'file');
    fprintf('Image %d: %s does not exist\n', i, fname);
    ok_f = 0;
  end
end
if ok_f
  disp('All images in design appear to exist');
end

%=======================================================================
case 'ana_cd'                      %-changes path to files in SPM design
%=======================================================================
% phiwave('ana_cd')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end;

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Change image path in design', 0);

% root path shown in output window
P = image_names(phiwD);
P = strvcat(P{:});
root_names = spm_str_manip(P, 'H');
spm_input(deblank(root_names(1,:)),1,'d','Common path is:');

% new root
newpath = spm_get([-1 0], '', 'New directory root for files');
if isempty(newpath), return, end

% do
phiwD = cd_images(phiwD, newpath);
phiw_arm('set', 'def_design', phiwD);

%=======================================================================
case 'ana_desmooth'           %-makes new SPM design for unsmoothed data
%=======================================================================
% phiwave('ana_desmooth')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end;
phiwD = prefix_images(phiwD, 'remove', 's');
phiw_arm('set', 'def_design', phiwD);
disp('Done');

%=======================================================================
case 'explicit_mask'                    %-sets explicit mask into design
%=======================================================================
% phiwave('explicit_mask')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end;
mask_img = spm_get([0 1], mars_veropts('get_img_ext'), ...
		   'Select explicit masking image for design');
if isempty(mask_img), return, end
phiwD = explicit_mask(phiwD, mask_img);
phiw_arm('set', 'def_design', phiwD);
disp('Done');

%=======================================================================
case 'add_images'                            %-add images to FMRI design
%=======================================================================
% phiwave('add_images')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end
if ~is_fmri(phiwD), return, end
phiwD = fill(phiwD, {'images'});
phiw_arm('update', 'def_design', phiwD);
phiw_arm('set_param', 'def_design', 'file_name', '');
phiw_arm('show_summary', 'def_design');

%=======================================================================
case 'edit_filter'                   %-add / edit filter for FMRI design
%=======================================================================
% phiwave('edit_filter')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end
if ~is_fmri(phiwD), return, end
tmp = {'filter'};
if ~strcmp(type(phiwD), 'SPM99'), tmp = [tmp {'autocorr'}]; end
phiwD = fill(phiwD, tmp);
phiw_arm('update', 'def_design', phiwD);
phiw_arm('set_param', 'def_design', 'file_name', '');
phiw_arm('show_summary', 'def_design');

%=======================================================================
case 'def_from_est'          %-sets default design from estimated design
%=======================================================================
% phiwave('def_from_est')
%-----------------------------------------------------------------------
phiwE = phiw_arm('get', 'est_design');
if isempty(phiwE), return, end;
errf = phiw_arm('set', 'def_design', phiwE);
if ~errf, phiwave('design_report'); end

%=======================================================================
case 'set_def'                           %-sets default design using GUI
%=======================================================================
% phiwave('set_def')
%-----------------------------------------------------------------------
if phiw_arm('set_ui', 'def_design'), return, end
phiwave('design_report');

%=======================================================================
case 'design_report'                         %-does explore design thing
%=======================================================================
% phiwave('design_report')
%-----------------------------------------------------------------------
phiwD = phiw_arm('get', 'def_design');
if isempty(phiwD), return, end;
spm('FnUIsetup','Explore design', 0);

fprintf('%-40s: ','Design reporting');
ui_report(phiwD, 'DesMtx');
ui_report(phiwD, 'DesRepUI');
fprintf('%30s\n','...done');

%=======================================================================
case 'estimate'                                       %-Estimates design
%=======================================================================
% phiwave('estimate')
%-----------------------------------------------------------------------
phiwD= phiw_arm('get', 'def_design');
if isempty(phiwD), return, end
if sf_prev_save('est_design') == -1, return, end
flags = mars_struct('merge', PHI.OPTIONS.wt, PHI.OPTIONS.statistics);
phiwRes = estimate(phiwD, [], flags);
phiw_arm('set', 'est_design', phiwRes);
phiw_arm('show_summary', 'est_design');

%=======================================================================
case 'set_results'          %-sets estimated design into global stucture
%=======================================================================
% donef = phiwave('set_results')
%-----------------------------------------------------------------------
% Set results, put results ROI data into roi_data container
varargout = {0};

% Check if there's anything we don't want to write over 
if sf_prev_save('est_design') == -1, return, end

% Do set
phiw_arm('set_ui', 'est_design');
if phiw_arm('isempty', 'est_design'), return, end

% Get design, set ROI data 
phiwRes = phiw_arm('get', 'est_design');

% Clear default contrast
if mars_struct('isthere', PHI, 'WORKSPACE', 'default_contrast')
  PHI.WORKSPACE.default_contrast = [];
  fprintf('Reset of estimated design, cleared default contrast...\n');
end

% Report on design
fprintf('%-40s: ','Design reporting');
ui_report(phiwRes, 'DesMtx');
ui_report(phiwRes, 'DesRepUI');
fprintf('%30s\n','...done');

varargout = {1};
return

%=======================================================================
case 'set_defcon'                                 %-set default contrast
%=======================================================================
% Ic = phiwave('set_defcon')
%-----------------------------------------------------------------------
varargout = {[]};
phiwRes = phiw_arm('get', 'est_design');
if isempty(phiwRes), return, end

% Setup input window
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Default contrast', 0);
Ic = mars_struct('getifthere',PHI, 'WORKSPACE', 'default_contrast');
if isempty(Ic)
  cname = '[Not set]';
else 
  xCon = get_contrasts(phiwRes);
  cname = xCon(Ic).name; 
end
spm_input(cname, 1, 'd', 'Default contrast');
opts = {'Quit', 'Set new default'};
if ~isempty(Ic), opts = [opts {'Clear default contrast'}]; end
switch spm_input('What to do?', '+1', 'm', opts, [1:length(opts)], 1);
 case 1
 case 2
  [Ic phiwRes changef] = ui_get_contrasts(phiwRes, 'T|F',1,...
			 'Select default contrast','',1);
  if changef
    phiw_arm('update', 'est_design', phiwRes);
  end
 case 3
  Ic = [];
end
PHI.WORKSPACE.default_contrast = Ic;
varargout = {Ic};
 
%=======================================================================
case 'merge_contrasts'                                %-import contrasts
%=======================================================================
% phiwave('merge_contrasts')
%-----------------------------------------------------------------------
D = phiw_arm('get', 'est_design');
if isempty(D), return, end
filter_spec = {...
    'SPM.mat','SPM: SPM.mat';...
    '*phiw_spm.mat','Phiwave: *phiw_spm.mat';...
    '*x?on.mat','xCon.mat file'};
[fn pn] = mars_uifile('get', ...
    filter_spec, ...
    'Source design/contrast file...');
if isequal(fn,0) | isequal(pn,0), return, end
fname = fullfile(pn, fn);
D2 = mardo(fname);

% has this got contrasts?
if ~has_contrasts(D2)
  error(['Cannot find contrasts in design/contrast file ' fname]);
end
  
% now try to trap case of contrast only file
if ~is_valid(D2)
  D2 = get_contrasts(D2);
end

[D Ic changef] = add_contrasts(D, D2, 'ui');
disp('Done');
if changef
  phiw_arm('update', 'est_design', D);
end

%=======================================================================
case 'add_trial_f'            %-add trial-specific F contrasts to design
%=======================================================================
% phiwave('add_trial_f')
%-----------------------------------------------------------------------
D = phiw_arm('get', 'est_design');
if isempty(D), return, end
if ~is_fmri(D)
  disp('Can only add trial specific F contrasts for FMRI designs');
  return
end
[D changef] = add_trial_f(D);
disp('Done');
if changef
  phiw_arm('update', 'est_design', D);
end


%=======================================================================
case 'writecons'                                     %-write contrast(s)
%=======================================================================
% phiwave('writecons')
%-----------------------------------------------------------------------
% Write contrast images only, update design as necessary
phiwRes = phiw_arm('get', 'est_design');
if isempty(phiwRes), return, end
Ic = mars_struct('getifthere', PHI, 'WORKSPACE', 'default_contrast');
if ~isempty(Ic)
  xCon = get_contrasts(phiwRes);
  fprintf('Using default contrast: %s\n', xCon(Ic).name);
end
flags = struct('t_only', 1, 'con_only', 1);
[phiwRes connos changef] = write_contrasts(phiwRes, Ic, flags);
if changef
  phiw_arm('update', 'est_design', phiwRes); 
end

%=======================================================================
case 'denoisecon'                                     %-denoise contrast
%=======================================================================
% phiwave('denoisecon')
%-----------------------------------------------------------------------
phiwRes = phiw_arm('get', 'est_design');
if isempty(phiwRes), return, end
Ic = mars_struct('getifthere', PHI, 'WORKSPACE', 'default_contrast');
if ~isempty(Ic)
  xCon = get_contrasts(phiwRes);
  fprintf('Using default contrast: %s\n', xCon(Ic).name);
end
[Vdcon Vderr phiwRes changef] = get_wdimg(phiwRes, Ic, PHI.OPTIONS.denoise);
if changef
  phiw_arm('update', 'est_design', phiwRes); 
end
if isempty(Vdcon),return,end
phiw_display('display', [], Vdcon);

%=======================================================================
case 'make'                                                       %-make
%=======================================================================
% phiwave('make' [,optfile])
%-----------------------------------------------------------------------
% runs Phiwave mex file compilation   
% 
% Inputs
% optfile    - optional options (mexopts) file to use for compile
%   
% You may want to look into the optimizations for mex compilation
% See the SPM99 spm_MAKE.sh file or SPM2 Makefile for examples
% 
% My favorite compilation flags for a pentium 4 system, linux, gcc are:
% -fomit-frame-pointer -O3 -march=pentium4 -mfpmath=sse -funroll-loops

if nargin < 2
  optfile = '';
else
  optfile = varargin{2};
end

if ~isempty(optfile)
  if ~exist(optfile, 'file')
    error(['optfile ' optfile ' does not appear to exist']);
  end
  optfile = [' -f ' optfile];
end

mexfiles = { {'uvi_wave'}, ...
	     {'do_wtx.c', 'do_iwtx.c'};...
	     {'@phiw_wvimg', 'private'}, {'pplot_elbow.c'} };
	     
pwd_orig = pwd;
phiwave_dir = fileparts(which('phiwave.m'));
if isempty(phiwave_dir)
  error('Can''t find phiwave on the matlab path');
end
try
  for d = 1:size(mexfiles, 1)
    cd(fullfile(phiwave_dir, mexfiles{d}{:}));
    files = mexfiles{d, 2};
    for f = 1:length(files)
      fprintf('Compiling %s\n', fullfile(pwd, files{f}));
      if isempty(optfile)
	mex(files{f});
      else
	mex(optfile, files{f});
      end
    end
  end
  cd(pwd_orig);
catch
  cd(pwd_orig);
  rethrow(lasterror);
end 
 
%=======================================================================
case 'error_log'                   %-makes file to help debugging errors
%=======================================================================
% fname = phiwave('error_log', fname);
%-----------------------------------------------------------------------
if nargin < 2
  fname = 'error_log.mat';
else
  fname = varargin{2};
end

e_log = struct('last_error', lasterr, ...
	       'm_ver', phiwave('ver'),...
	       'mars', PHI);
savestruct(fname, e_log);
if ~isempty(which('zip'))
  zip([fname '.zip'], fname);
  fname = [fname '.zip'];
end
disp(['Saved error log as ' fname]);

%=======================================================================
case 'phiw_menu'                     %-menu selection of phiwave actions 
%=======================================================================
% phiwave('phiw_menu',tstr,pstr,tasks_str,tasks)
%-----------------------------------------------------------------------

[tstr pstr optfields optlabs] = deal(varargin{2:5}); 
if nargin < 6
  optargs = cell(1, length(optfields));
else
  optargs = varargin{6};
end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup',tstr);
of_end = length(optfields)+1;
my_task = spm_input(pstr, '+1', 'm',...
	      {optlabs{:} 'Quit'},...
	      [1:of_end],of_end);
if my_task == of_end, return, end
phiwave(optfields{my_task}{:});

%=======================================================================
otherwise                                        %-Unknown action string
%=======================================================================
error(['Unknown action string: ' Action])

%=======================================================================
end
return
