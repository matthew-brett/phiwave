function varargout=phiwave(varargin) 
% Startup, callback and utility routine for PhiWave
%
% PhiWave: Functional image wavelet analysis 
%
% PhiWave (the collection of files listed by Contents.m) is copyright under
% the GNU general public license.  Please see phiw_licence.man for details.
% 
% PhiWave written by 
% Federico Turkheimer, Matthew Brett, John Aston, Vincent Cunningham
%
% Data structures, programming style and portions of the code rely heavily
% on SPM99 (http://www.fil.ion.ucl.ac.uk/spm99), which is also released
% under the GNU public licence.  Many thanks the SPM authors:
% (John Ashburner, Karl Friston, Andrew Holmes, Jean-Baptiste Poline et al).
%
% $Id: phiwave.m,v 1.1.1.1 2004/06/25 15:20:40 matthewbrett Exp $
  
% PhiWave version
PWver = 0.2;  % alpha minus 

% PhiWave defaults in global variable structure
global PHIWAVE;

%-Format arguments
%-----------------------------------------------------------------------
if nargin == 0, Action='Startup'; else, Action = varargin{1}; end

%=======================================================================
switch lower(Action), case 'startup'             %-Start phiwave
%=======================================================================

%-Turn on warning messages for debugging
warning always, warning backtrace

% splash screen once per session
splashf = isempty(PHIWAVE);

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

% check paths 
if isempty(which('spm'))
  error('SPM does not appear to be on the path')
end

% promote spm_spm directory
pwpath = fileparts(which('phiwave.m'));
phwd = fullfile(pwpath, 'spmrep');
addpath(phwd,'-begin');
fprintf('Phiwave analysis function prepended to path\n');

% read any necessary defaults
[pwdefs sourcestr] = phiw_options('Defaults');
if isempty(PHIWAVE)
  fprintf('PhiWave defaults loaded from %s\n',sourcestr);
end
PHIWAVE = phiw_options('fill',PHIWAVE, pwdefs);

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
funcs = {'global PHIWAVE; PHIWAVE=phiw_options(''load'');',...
	 'phiw_options(''save'');',...
	 'global PHIWAVE; PHIWAVE=phiw_options(''edit'');',...
	 ['global PHIWAVE; [PHIWAVE str]=phiw_options(''defaults'');' ...
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
 
case 'str2fname'
% accepts string, attempts return of string for valid filename
 if nargin < 2
   error('Need to specify string');
 end
 str = varargin{2};
 % forbidden chars in file name
 badchars = unique([filesep '/\ :;.''"~*?<>']);

 tmp = find(ismember(str, badchars));   
 if ~isempty(tmp)
   str(tmp) = '_';
   dt = diff(tmp);
   if ~isempty(dt)
     str(tmp(dt==1))=[];
   end
 end
 varargout={str};
 
case 'get_spmmat'
 % accepts or fetches name of SPM.mat file, returns SPM.mat structure
 if nargin < 2
   spmmat = [];
 else
   spmmat = varargin{2};
 end
 swd = [];
 if isempty(spmmat)
  spmmat = spm_get(1, 'SPM.mat', 'Select analysis');
  if isempty(spmmat),return,end
 end
 if ischar(spmmat) % assume is SPM.mat file name
   swd    = spm_str_manip(spmmat,'H');
   spmmat = load(spmmat);
   spmmat.swd = swd;
 elseif isstruct(spmmat)
   if isfield(spmmat,'swd')
     swd = spmmat.swd;
   end
 else
   error('Requires string or struct as input');
 end

 % check the structure
 if ~isfield(spmmat,'SPMid')
   %-SPM.mat pre SPM99
   error('Incompatible SPM.mat - old SPM results format!?')
 end

 % remove large and unuseda field
 if isfield(spmmat, 'XYZ')
   rmfield(spmmat, 'XYZ');
 end
 
 varargout = {spmmat, swd};

case 'ana_desmooth'
anamat = spm_get([0 1], 'SPM*.mat', 'Analysis -> unsmoothed');
if ~isempty(anamat)
  newdir = spm_get(-1, '', 'Directory to save analysis');
  prefix = 's';
  phiwave('ana_deprefix', anamat, newdir, prefix);
end
  
case 'ana_deprefix'
if nargin < 2
  anamat = spm_get(1, 'SPM*.mat', 'Analysis to deprefix');
else
  anamat = varargin{2};
end
if nargin < 3
  newdir = spm_get(-1, '', 'Directory to save analysis');
else
  newdir = varargin{3};
end
if nargin < 4
  prefix = 's';
else
  prefix = varargin{4};
end

ana = load(anamat);
if ~isfield(ana, 'VY')
  error('No VY vols in this mat file')
end
if ~isfield(ana.VY, 'fname')
  error('VY does not contain fname field')
end
files = strvcat(ana.VY(:).fname);
fpaths = spm_str_manip(files, 'h');
fns = spm_str_manip(files, 't');
if all(fns(:,1) == prefix)
  fns(:,1) = [];
  newfns = cellstr(strcat(fpaths, filesep, fns));
  [ana.VY(:).fname] = deal(newfns{:});
  [pn fn e] = fileparts(anamat);
  newanamat = fullfile(newdir,[fn e]);
  if exist(newanamat, 'file')
    spm_unlink(newanamat);
  end
  savestruct(newanamat,ana);
  fprintf('Done...\n');
else
  warning(['Analysis files not all prefixed with ''' prefix ''', no new' ...
		    ' file saved'])
end

%=======================================================================
otherwise                                        %-Unknown action string
%=======================================================================
error('Unknown action string')

%=======================================================================
end
return