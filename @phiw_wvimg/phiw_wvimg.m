function wvimg = phiw_wvimg(inpimg,input_options,waveobj,scales)
% phiw_wvimg - constructor for container for wt'ed image
% function call takes four forms
% wvimg = phiw_wvimg;   no args, returns default object
% wvimg = phiw_wvimg(wv_img); object passed, object returned
% wvimg = phiw_wvimg(inpimg,input_options,wavelet,scales)
%         (Four imput arguments)
%         Creates wavelet structure from _untransformed_ data
%         in inpimg (either SPM vol struct, or data matrix)
%         and (possibly queues) transform with wavelet, scales
% wvimg = phiw_wvimg(inpimg, [input_options], [twvimg])
%         (between one and three input arguments, where first argument is
%         not a wvimg object already)
%         Puts previously _transformed_ data from inpimg into wvimg object
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
%         input_options = struct with options, with fields below. Options fall
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
% The constructor can also be called to give class functions, where the
% name of the class function is a character string which is one of:
%    'is_wted'   returns 1 if passed vol struct is for wt'ed image
%    'orig_vol'  returns original vol struct from wt'ed vol
%
% This class relies on lots of SPM routines
% (spm_read_vols, spm_write_vol, spm_type, spm_vol, etc)
%
% Matthew Brett 21/5/01 (C/NZD)
%
% $Id: phiw_wvimg.m,v 1.5 2005/04/03 06:58:49 matthewbrett Exp $

myclass = 'phiw_wvimg';

% default object struct; all fields are empty to allow fill below
% it has to be this way to make sure all fields are in the same order
defstruct = struct(...
    'ovol', [], ...
    'wvol', [], ...
    'options', [], ...
    'img', [], ...
    'wavelet', [], ...
    'scales', [], ...
    'oimgi', [], ...
    'descrip', '', ...
    'wtf', [], ...
    'changef', []);

% no args, return default object
if nargin < 1
  wvimg = class(defstruct,myclass);
  return
end

% wvimg object passed as first arg, return it unaltered
if isa(inpimg, myclass)
  wvimg = inpimg;
  return
end

% set unpassed inputs to empty
if nargin < 2, input_options = [];end
if nargin < 3, waveobj = [];end
if nargin < 4, scales = [];end

% overall default options
defopts = struct('datatype','float', ...
		 'wtprefix','wt_',...
		 'verbose',1,...
		 'descrip','', ...
		 'noproc',0, ...
		 'remap',0);

% parse out string action calls (class functions)
if ischar(inpimg)
  s_def = struct('noproc',1);
  switch inpimg
   case 'is_wted'
    % Second argument is vol struct
    VY = input_options;
    if ~isstruct(VY), error('Need vol struct as second argument'); end
    wvimg = ~isempty(phiw_wvimg(input_options(1),s_def));
    return
   case 'orig_vol'
    % Second argument is (array of) vol structs
    VY = input_options;
    if nargin < 2, error('Need vol struct'); end
    for v = 1:prod(size(VY))
      wvobj = phiw_wvimg(VY(v), s_def);
      if isempty(wvobj), oVY(v) = VY(v); else oVY(v) = wvobj(v).ovol; end
    end
    wvimg = reshape(oVY, size(VY));
    return
  end
end

% process passed options
if isfield(input_options,'datatype') & ~ischar(input_options.datatype)
  input_options.datatype = spm_type(input_options.datatype);
end

% get passed options from input
filled_opts = mars_struct('ffillsplit', defopts, input_options);

% process inpimg argument
% ----------------------------------------------
% remap volume if specified and is vol struct
if isstruct(inpimg) & filled_opts.remap
  inpimg = inpimg.fname;
end
% convert string inpimg input to SPM vol struct
if ischar(inpimg)
  inpimg = spm_vol(inpimg);
end

% insert necessary data into wvimg structure to start
[wvimg others] = mars_struct('ffillsplit', defstruct, ...
			     struct(...
				 'img', inpimg, ...
				 'options', filled_opts, ...
				 'wtf', 0, ...
				 'descrip', filled_opts.descrip));

% process different types of function call
if nargin > 3  % must be untransformed data with wavelet and scales
  
  if ~isa(waveobj,'phiw_wavelet') | isempty(scales)
    error('Need wavelet and scales for untransformed data');
  end

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
  wvimg.wavelet = waveobj;
  wvimg.scales = scales;
  
  % set bits for output image struct
  wvimg.wvol = mars_struct('fillafromb', wvimg.wvol, wvimg.ovol);
  wvimg.wvol.dim(1:3) = outdim(wvimg.wavelet, wvimg.ovol.dim(1:3));

else
  
  % this must be a wt'ed vol struct for putting into object
  wvimg.wtf = 1;

  % We need phiw_wvimg template information.  We can get it from the input
  % vol struct, or from the third argument.  Third argument can be empty
  % (missing), vol struct, or phiw_wvimg object...
    
  % if no third argument, try and get template from .mat file
  if isempty(waveobj), waveobj = inpimg; end
  
  % look for wavelet information in vol struct 
  if isstruct(waveobj)  
    waveobj = pr_getwave(waveobj);
  end
  
  % no template obtainable -> give up and return empty
  if isempty(waveobj), wvimg = []; return, end
  
  % fill any missing fields from template
  wvimg = mars_struct('fillafromb', wvimg, struct(waveobj));
  
  % and fill any missing options from defaults
  wvimg.options = mars_struct('fillafromb', wvimg.options, defopts);
  
  % input vol struct overrides template vol struct
  if isstruct(inpimg)
    wvimg.wvol = inpimg;
  else % input image dimensions override template
    wvimg.wvol.dim(1:3) = size(wvimg.img);
  end;

end

% set any options passed, overriding previous
if isfield(input_options,'datatype') & ~isempty(input_options.datatype)
  wvimg.wvol.dim(4) = spm_type(input_options.datatype);
end

% fill the vol structs with empty fields 
evol = struct('fname','','mat',eye(4),'dim',[1 1 1], ...
	      'pinfo',ones(3,1),'descrip','');
wvimg.ovol = mars_struct('fillafromb', wvimg.ovol,evol);
wvimg.wvol = mars_struct('fillafromb', wvimg.wvol,evol);

% set datatypes if missing
if length(wvimg.ovol.dim) < 4
  wvimg.ovol.dim(4) = spm_type(wvimg.options.datatype);
end
if length(wvimg.wvol.dim) < 4
  wvimg.wvol.dim(4) = spm_type(wvimg.options.datatype);
end

% bless (as we say in perl)
wvimg = class(wvimg,myclass);

% do processing as necessary
if ~wvimg.options.noproc
  wvimg = doproc(wvimg);
end

% unset first pass options
wvimg.options.noproc = 0;
wvimg.options.remap = 0;
wvimg.options.descrip = '';

return

  