function wvimg = phiw_wvimg(inpimg,options,waveobj,scales)
% phiw_wvimg - constructor for container for wt'ed image
% function call takes four forms
% wvimg = phiw_wvimg;   no args, returns default object
% wvimg = phiw_wvimg(wv_img); object passed, object returned
% wvimg = phiw_wvimg(inpimg,options,wavelet,scales)
%         Creates wavelet structure from unstransformed data
%         in inpimg (either SPM vol struct, or data matrix)
%         and (possibly queues) transform with wavelet, scales
% wvimg = phiw_wvimg(inpimg, [options], [twvimg])
%         Puts previously transformed data from inpimg into wvimg object
%         This can have three forms:
%         1) If no third arg - try to derive info from inpimg .mat file
%         (return empty if not successful)
%         2) If third arg is phiw_wvimg object, use this as template
%         3) If third arg is vol struct, try and get info from that .mat
%         file (return empty if not successful)
%
% object fields are:
%         ovol    = SPM vol struct describing not wt'ed data
%                   with fields: dim, mat, fname, pinfo
%         wvol    = wavelet transformed SPM vol struct representing dimensions,
%                   .mat data, filename for image data, datatype;
%         options = struct with options, with fields below. Options fall
%                   into two categories; permanent, and object creation
%                   options (noproc, remap); the latter are reset to 0 by
%                   this routine  
%         img     = contains matrix data, or SPM vol struct representing
%                   data
%         wtf     = set if data has been wavelet transformed 
%         changef = set if data has been changed since passed
%         wavelet = phiw_wavelet object giving wavelet for transform;
%         scales  = number of coarsest scale for wt;
%         descrip = extended text description field;
%
% passed options can be empty, or one or more fields from this list
% defaults in [], OCO = object creation option
% 
%         datatype  - datatype for transformed data ['float']
%         wtprefix  - default prefix for transformed file ['wt_']
%         iwtprefix - default prefix for inverted wt file ['iwt_']
%         verbose   - flag to output feedback in matlab window [1]
%         descrip   - description (appended to fulldescrip obj field)
%                     ['']  OCO
%         noproc    - if not zero defer vol struct load and any wavelet
%                     transform [0] OCO 
%         remap     - forces remap of passed vol struct [0] OCO
%
% wvimg returned is empty if inputs are incorrect
% 
% Routine does little filling of fields, and relies on methods filling
% the fields that they need, or complaining if appropriate
%
% This class relies on SPM 99 routines
% (spm_read_vols, spm_write_vol, spm_type, spm_vol, etc)
%
% Matthew Brett 21/5/01 (C/NZD)
%
% $Id: phiw_wvimg.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

myname = 'phiw_wvimg';


% wvimg object passed as first arg, return it
if nargin > 0 & isa(inpimg, myname)
  wvimg = inpimg;
  return
end

% set unpassed inputs to empty
if nargin < 2, options = [];end
if nargin < 3, waveobj = [];end
if nargin < 4, scales = [];end

% default input options (object creation options)
definpopts = struct('noproc',0,'remap',0,'descrip','');

% overall default options
defopts = struct('datatype','float','wtprefix','wt_',...
		       'iwtprefix','iwt_','verbose',1,...
		       'descrip','','noproc',0,'remap',0);

% default object; all fields are empty to allow fill below
% it has to be this way to make sure all fields are in the same order
defobj.ovol = [];
defobj.wvol = [];
defobj.options = [];
defobj.img = [];
defobj.wavelet = [];
defobj.scales = [];
defobj.oimgi = [];
defobj.descrip = '';
defobj.wtf = [];
defobj.changef = [];

% no args, return default object
if nargin < 1
  wvimg = class(defobj,myname);
  return
end

% process passed options
if isfield(options,'datatype') & ~ischar(options.datatype)
  options.datatype = spm_type(options.datatype);
end

% get passed options from input
inpopts = fillafromb(options,definpopts);

% process inpimg argument
% ----------------------------------------------
% remap volume if specified and is vol struct
if isstruct(inpimg) & inpopts.remap
  inpimg = inpimg.fname;
end
% convert string inpimg input to SPM vol struct
if ischar(inpimg)
  inpimg = spm_vol(inpimg);
end

% establish type of input data
if isstruct(waveobj)  % third arg is vol struct - lookfor wave info
  waveobj = getwave(waveobj);
  if isempty(waveobj), wvimg = [];return;end
end
wtf = nargin < 4 | isa(waveobj,myname); 

% insert necessary data into wvimg structure to start
wvimg = defobj;
wvimg.img = inpimg;
wvimg.options = inpopts;
wvimg.wtf = wtf;
wvimg.descrip = inpopts.descrip;

% process different types of function call
if wtf
  % this must be a wt image

  % check this is a sensible third arg if present
  if nargin > 2 & ~isa(waveobj, myname)
    error('Odd third argument')
  end

  % if no template available, try and get template from .mat file
  if isempty(waveobj), waveobj = getwave(inpimg);end
  
  % no template obtainable -> give up and return empty
  if isempty(waveobj), wvimg = []; return, end
  
  % fill from template
  wvimg = fillafromb(wvimg, struct(waveobj));
  
  % and fill options from defaults
  wvimg.options = fillafromb(wvimg.options, defopts);
  
  % input vol struct overrides template vol struct
  if isstruct(inpimg)
    wvimg.wvol = inpimg;
  else % input image dimensions override template
    wvimg.wvol.dim(1:3) = size(wvimg.img);
  end;

else
  % untransformed data

  % fill options from defaults
  wvimg.options = fillafromb(wvimg.options, defopts);

  % set ovol and ouput filename 
  if isstruct(inpimg)
    wvimg.ovol = inpimg;
    wvimg.descrip = strvcat(wvimg.descrip,wvimg.ovol.descrip);
    % set output file name by adding wt prefix
    [p f e] = fileparts(wvimg.ovol.fname);
    wvimg.wvol.fname = fullfile(p,[wvimg.options.wtprefix f e]);
  elseif ~isempty(inpimg) & isnumeric(inpimg)
    % maybe data passed was a matrix, we'll do our best
    sz = ones(1,3);
    sz(1:length(size(inpimg))) = size(inpimg);
    offs = -(sz+1)/2;
    wvimg.ovol = struct('dim', [sz spm_type(wvimg.options.datatype)],...
		'pinfo',[1 0 0]',...
		'fname',[],...
		'mat', [1 0 0 offs(1); 0 1 0 offs(2); 0 0 1 offs(3); ...
		    0 0 0 1]);
  end
  
  % last two args are wavelet and scales
  if nargin < 4 | ~isa(waveobj,'phiw_wavelet') | isempty(scales) 
    error('Need wavelet and scales for untransformed data');
  end
  wvimg.wavelet = waveobj;
  wvimg.scales = scales;
  
  % set bits for output image struct
  wvimg.wvol = fillafromb(wvimg.wvol, wvimg.ovol);
  wvimg.wvol.dim(1:3) = outdim(wvimg.wavelet, wvimg.ovol.dim(1:3));
end

% set any options passed, overriding previous
if isfield(options,'datatype') & ~isempty(options.datatype)
  wvimg.wvol.dim(4) = spm_type(options.datatype);
end

% fill the vol structs with empty fields 
evol = struct('fname','','mat',eye(4),'dim',[1 1 1], ...
	      'pinfo',ones(3,1),'descrip','');
wvimg.ovol = fillafromb(wvimg.ovol,evol);
wvimg.wvol = fillafromb(wvimg.wvol,evol);

% set datatypes if missing
if length(wvimg.ovol.dim) < 4
  wvimg.ovol.dim(4) = spm_type(wvimg.options.datatype);
end
if length(wvimg.wvol.dim) < 4
  wvimg.wvol.dim(4) = spm_type(wvimg.options.datatype);
end

% bless (as we say in perl)
wvimg = class(wvimg,myname);

% do processing as necessary
if ~wvimg.options.noproc
  wvimg = doproc(wvimg);
end

% unset first pass options
wvimg.options.noproc = 0;
wvimg.options.remap = 0;
wvimg.options.descrip = '';

return

  