function [o, others] = phido(params, others, passf)
% phido - class constructor for MarsBaR design object
% FORMAT [o, others] = phido(params, others, passf)
% inputs [defaults]
% params  -  one of:            
%            - string, specifying SPM design file, OR
%            - mardo object OR
%            - structure, which can:
%               contain SPM/MarsBaR design OR
%               contain fields for mardo object or phido object.
%               Fields should include 'des_struct', containing design
%               structure
% others  - any other fields for mardo object or phido object or children
%           Fields for phido object are:
%           [none, so far]
% passf   - if 1, or not passed, will try children objects to see if
%           they would like to own this design
%
% outputs
% o       - phido object
% others  - any unrecognized fields from params, others
%
% phido is pronounced like Fido, the dog's name.
% 
% phido is the parent for containers of mardo designs - see the mardo
% constructor functions for details. The phido object itself is only a
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
% $Id: phido.m,v 1.9 2005/05/31 11:11:32 matthewbrett Exp $

myclass = 'phido';
cvs_v   = mars_cvs_version(myclass);

% Default object structure
defstruct = [];

if nargin < 1
  defstruct.cvs_version = cvs_v;
  o = class(defstruct, myclass);
  others = [];
  return
end
if nargin < 2
  others = [];
end
if nargin < 3
  passf = 1;
end

% Deal with passed objects of this (or child) class
if isa(params, myclass)
  o = params;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  % (but there are none for now, so just split)
  [p others] = mars_struct('split', others, defstruct);
  return
end

% send design to mardo
[mardo_o others] = mardo(params, others);

% fill params with defaults, parse into fields for this object, children
[params, others] = mars_struct('ffillsplit', defstruct, others);

% add cvs tag
params.cvs_version = cvs_v;

% set the phido object
o  = class(params, myclass);

% If requested (passf) pass it to candidate children 
if passf
  switch lower(type(mardo_o))
   case 'spm99'
    [o others] = phido_99(mardo_o, others, o);
   case 'spm2'
    % [o others] = phido_2(mardo_o, others, o);
    mardo_o = mardo_99(mardo_o);
    [o others] = phido_99(mardo_o, others, o);
  end
end

return
