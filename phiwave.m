function varargout=phiwave(varargin) 
% Startup, callback and utility routine for PhiWave
%
% PhiWave: Functional image wavelet analysis 
%
% PhiWave (the collection of files listed by Contents.m) is copyright under
% the GNU general public license.  Please see phiw_licence.man for details.
% 
% PhiWave written by 
% John Aston, Matthew Brett, Rainer Hinz and Federico Turkheimer
%
% Data structures, programming style and portions of the code rely heavily
% on SPM (http://www.fil.ion.ucl.ac.uk/spm), which is also released
% under the GNU public licence.  Many thanks the SPM authors:
% (John Ashburner, Karl Friston, Andrew Holmes, Jean-Baptiste Poline et al).
%
% $Id: phiwave.m,v 1.4 2004/09/14 03:41:26 matthewbrett Exp $
  
% PhiWave version
PWver = 2.2;  % alpha 

% PhiWave defaults in global variable structure
global PHI;

%-Format arguments
%-----------------------------------------------------------------------
if nargin == 0, Action='Startup'; else, Action = varargin{1}; end

%=======================================================================
switch lower(Action), case 'startup'             %-Start phiwave
%=======================================================================

%-Turn on warning messages for debugging
warning always, warning backtrace

% splash screen once per session
splashf = isempty(PHI);

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

% SPM buttons that need disabling
phiwave('SPMdesconts','off');

%-Reveal windows
%-----------------------------------------------------------------------
set([Fmenu],'Visible','on')

%=======================================================================
case 'on'                              %-Initialise phiwave
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

% promote spm_spm directory
pwpath = fileparts(which('phiwave.m'));
phwd = fullfile(pwpath, 'spmrep');
addpath(phwd,'-begin');
fprintf('Phiwave analysis function prepended to path\n');

% read any necessary defaults
[pwdefs sourcestr] = phiw_options('Defaults');
if isempty(PHI)
  fprintf('PhiWave defaults loaded from %s\n',sourcestr);
end
PHI = phiw_options('fill',PHI, pwdefs);

%=======================================================================
case 'off'                             %-Unload phiwave 
%=======================================================================
% phiwave('Off')
%-----------------------------------------------------------------------
% remove phiwave spm_spm directory
pwpath = fileparts(which('phiwave.m'));
phwd = fullfile(pwpath, 'spmrep');
rmpath(phwd);
fprintf('Phiwave analysis function removed from path\n');

%=======================================================================
case 'cfgfile'                             %-file with phiwave cfg
%=======================================================================
% cfgfn  = phiwave('cfgfile')
cfgfile = 'phiwavecfg.mat';
varargout = {which(cfgfile), cfgfile}; 

%=======================================================================
case 'createmenuwin'                              %-Draw phiwave menu window
%=======================================================================
% Fmenu = phiwave('CreateMenuWin',Vis)
if nargin<2, Vis='on'; else, Vis=varargin{2}; end

%-Close any existing 'Phiwave' 'Tag'ged windows
delete(spm_figure('FindWin','PhiWave'))

% Version etc info
[PWver,PWc] = phiwave('Ver');

%-Get size and scalings and create Menu window
%-----------------------------------------------------------------------
WS   = spm('WinScale');				%-Window scaling factors
FS   = spm('FontSizes');			%-Scaled font sizes
PF   = spm_platform('fonts');			%-Font names (for this platform)
Rect = [50 600 300 234];           		%-Raw size menu window rectangle
bno = 4; bgno = 5;
bgapr = 0.25;
bh = Rect(4) / (bno + bgno*bgapr);              % Button height
gh = bh * bgapr;                                  % Button gap
by = fliplr(cumsum([0 ones(1, bno-1)*(bh+gh)])+gh);
bx = Rect(3)*0.1;
bw = Rect(3)*0.8;
Fmenu = figure('IntegerHandle','off',...
	'Name',sprintf('%s',PWc),...
	'NumberTitle','off',...
	'Tag','PhiWave',...
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
	'Renderer','zbuffer',...
	'Visible','off');

%-Objects with Callbacks - main PhiWave routines
%=======================================================================

funcs = {'phiwave(''ana_desmooth'')',...
	 'spm_spm_ui(''cfg'',spm_spm_ui(''DesDefs_PET''))',...
	 '[X,Sess] = spm_fmri_spm_ui',...		    
	 'spm_spm_ui(''cfg'',spm_spm_ui(''DesDefs_Stats''))',...
	 'spm pointer watch, spm_DesRep; spm pointer arrow',...
	 'phiwave(''estimate'')'};

uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Design...'...
		    '|Convert|PET models',...
		    '|FMRI models|Basic models|Explore|Estimate'],...
	  'Position',[bx by(1) bw bh].*WS,...
	  'ToolTipString','Design specification...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

funcs = {'phiwave(''writecons'')',...
	 'phiwave(''denoisecon'')',...
	 'phiwave(''showcon'', ''slices'')',...
	 'phiwave(''showcon'', ''orth'')'};
uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Contrast...'...
		    '|Specify/write contrast(s)' ...
		    '|Specify/denoise comparison' ...
		    '|Display slices|Display sections'],...
	  'Position',[bx by(2) bw bh].*WS,...
	  'ToolTipString','Write/display contrasts...',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);
funcs = {'global PHI; PHI=phiw_options(''load'');',...
	 'phiw_options(''save'');',...
	 'global PHI; PHI=phiw_options(''edit'');',...
	 ['global PHI; [PHI str]=phiw_options(''defaults'');' ...
	  ' fprintf(''Defaults loaded from %s\n'', str)']};
	 
uicontrol(Fmenu,'Style','PopUp',...
	  'String',['Options...'...
		  '|Load options|Save options|Edit options|Restore defaults'],...
	  'Position',[bx by(3) bw bh].*WS,...
	  'ToolTipString','Load/save/edit PhiWave options',...
	  'CallBack','spm(''PopUpCB'',gcbo)',...
	  'UserData',funcs);

uicontrol(Fmenu,'String','Quit',	'Position',[bx by(4) bw bh].*WS,...
	'ToolTipString','exit PhiWave',...
	'ForeGroundColor','r',		'Interruptible','off',...
	'CallBack','phiwave(''Quit'')');

%-----------------------------------------------------------------------
set(Fmenu,'CloseRequestFcn','phiwave(''Quit'')')
set(Fmenu,'Visible',Vis)
varargout = {Fmenu};

%=======================================================================
case 'ver'                                      %-Return PhiWave version
%=======================================================================
% phiwave('Ver')
%-----------------------------------------------------------------------
varargout = {PWver, 'PhiWave - FI wavelet analysis'};

%=======================================================================
case 'estimate'                                 %-Estimate callback
%=======================================================================
% phiwave('estimate')
%-----------------------------------------------------------------------
if exist(fullfile('.','SPM.mat'),'file') & ...
      spm_input({'Current directory contains existing SPM stats files:',...
		 ['(pwd = ',pwd,')'],' ',...
		 'Continuing will overwrite existing results!'},1,'bd',...
		'stop|continue',[1,0],1)
  tmp=0; 
else
  tmp=1; 
end
if tmp
  tmp = load(spm_get(1,'SPMcfg.mat','Select SPMcfg.mat...'));
  if isfield(tmp,'Sess') & ~isempty(tmp.Sess)
    spm_spm(tmp.VY,tmp.xX,tmp.xM,tmp.F_iX0,tmp.Sess,tmp.xsDes);
  elseif isfield(tmp,'xC')
    spm_spm(tmp.VY,tmp.xX,tmp.xM,tmp.F_iX0,tmp.xC,tmp.xsDes);
  end
end

%=======================================================================
case 'quit'                                      %-Quit PhiWave and clean up
%=======================================================================
% phiwave('Quit')
%-----------------------------------------------------------------------

% reenable SPM controls
phiwave('SPMdesconts','on');

% do path stuff
phiwave('off');

%-Close any existing 'Phiwave' 'Tag'ged windows
delete(spm_figure('FindWin','PhiWave'))
fprintf('Arrivederci...\n\n')

%=======================================================================
case 'spmdesconts'                  %-Enable/disable SPM design controls
%=======================================================================
% dH = phiwave('SPMdesconts', 'off'|'on')
%-----------------------------------------------------------------------
Fmenu = spm_figure('FindWin','Menu');
if isempty(Fmenu)
  return
end
DStrs = {'PET/SPECT models', 'fMRI models','Basic models'...
	 'Explore design', 'Estimate', 'Results'};
dH = [];
for i = 1:length(DStrs)
  dH = [dH findobj(Fmenu,'String', DStrs{i})];
end
if nargin > 1
  set(dH, 'Enable', varargin{2});
end

%=======================================================================
case 'writecons'                                  %-write contrast(s)
%=======================================================================
% phiwave('writecons')
%-----------------------------------------------------------------------
% Write contrast images only
phiw_write_contrasts([],[],[],'c');

%=======================================================================
case 'denoisecon'                                  %-denoise contrast
%=======================================================================
% phiwave('denoisecon')
%-----------------------------------------------------------------------
V = phiw_get_wdimg;
if isempty(V),return,end
[Finter,Fgraph,CmdLine] = spm('FnUIsetup','PhiWave Display');
tmp = spm_input('Display image', 1, 'b', 'Slices|Sections|Cancel', [1 2 ...
		    0], 1);
if tmp
  if tmp==1, t ='slices'; else t='orth';end
  phiw_display('display',t, V);
end

%=======================================================================
case 'showcon'                           %-display activation image
%=======================================================================
% phiwave('showcon', disptype, fname)
%-----------------------------------------------------------------------
if nargin < 2
  disptype = 'orth'
else
  disptype = varargin{2};
end
if nargin < 3
  fname = [];
else
  fname = varargin{3};
end
phiw_display('display', disptype, fname);

case 'splash'
 % Shows splash screen  
 WS   = spm('WinScale');		%-Window scaling factors
 [X,map] = imread('phiwave.jpg');
 aspct = size(X,1) / size(X,2);
 ww = 400;
 srect = [200 300 ww ww*aspct] .* WS;   %-Scaled size splash rectangle
 h = figure('visible','off',...
	    'menubar','none',...
	    'numbertitle','off',...
	    'name','Welcome to PhiWave',...
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
case 'make'                                                       %-make
%=======================================================================
% phiwave('make' [,optfile])
%-----------------------------------------------------------------------
% runs PhiWave mex file compilation   
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

mexfiles = { {'@phiw_wavelet', 'private'}, ...
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
otherwise                                        %-Unknown action string
%=======================================================================
error('Unknown action string')

%=======================================================================
end
return