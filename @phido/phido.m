function [o, others] = phido(des, params, passf)
% phido - class constructor for MarsBaR design object
% inputs [defaults]
% des     - SPM design, which can be a mardo object, or another SPM
%           design format recognized by the mardo constructor - see help mardo for
%           details.
% params  - structure containing fields for phido object, which are
%           - wavelet     - phiwave wavelet object to transform images
%           - scales      - scales for wavelet transform
%           - wtprefix    - prefix for wavelet transformed files
%           - maskthresh  - threshold for mask image
% passf   - if 1, or not passed, will try children objects to see if
%           they would like to own this design
%
% outputs
% o       - phido object
% others  - any unrecognized fields from params, for processing by
%           children
%
% phido is pronounced like Fido, the dog's name.
% 
% phido is the parent for containers of mardo designs - see the mardo
% constructor functions for details. The phido object itself if only a
% placeholder for various settings - contained in the object fields.  The
% SPM / MarsBaR design is passed to the children of this class, either
% phido_99 or phido_2.  If the design is not suitable for either, the phido
% object has no use for it, and throws it away. If the (99 or 2) classes
% claim the object, they return an object of class (99 or 2), which inherits
% the phido class just created in this call to the object.
% 
% Note the "passf" input flag; this is a trick to allow the other phido
% classes (99 and 2) to create a phido object for them to inherit,
% without this constructor passing the phido object back to the other
% classes, creating an infinite loop.  So, it is by default set to 1, and
% the newly created phido object is passed to the other phido classes for
% them to claim ownership.  The other phido classes can call this
% constructor with passf set to 0 in order for the constructor merely to
% make a phido object, without passing back to the other classes. 
% 
% $Id: phido.m,v 1.6 2004/09/19 03:15:31 matthewbrett Exp $

myclass = 'phido';
defstruct = struct('wavelet',  phiw_lemarie(2), ...
		   'scales',   4, ...
		   'wtprefix', 'wv_', ...
		   'maskthresh', 0.05);

if nargin < 1
  des = [];
end
if nargin < 2
  params = [];
end
if nargin < 2
  passf = 1;
end
if isa(des, myclass)
  o = des;
  return
end

% send design to mardo
[mardo_o params] = mardo(des, params);

% fill params with defaults, parse into fields for this object, children
[params, others] = mars_struct('ffillsplit', defstruct, params);

% add cvs tag
params.cvs_version = mars_cvs_version(myclass);

% set the phido object
o  = class(params, myclass);

% If requested (passf) pass it to candidate children 
if passf
  switch lower(type(mardo_o))
   case 'spm99'
    [o others] = phido_99(mardo_o, others, o);
   case 'spm2'
    [o others] = phido_2(mardo_o, others, o);
  end
end

return
