function [o, others] = phido_99(params, others, phido_o)
% class constructor for SPM99 phiwave design object
% FORMAT [o, others] = phido_99(params, others, phido_o)
%
% Inputs  
% params  -  one of:
%            - string, specifying SPM99 design file, OR
%            - structure, which can:
%               contain SPM99/MarsBaR design or
%               contain fields for mardo_99 object, which should include
%               'des_struct', containing design structure
% others  - structure, containing extra fields for object (or parent)
% phido_o - (optional) phido object to inherit from
%
% Outputs
% o       - phido_99 object (unless disowned)
% others  - any unrecognized fields from params, others
%
% This object may be called from the phido object contructor with a mardo
% and phido object as input, or called directly.  The container makes no
% attempt to check if this is really an SPM99 design.
%
% $Id: phido_99.m,v 1.6 2004/11/18 18:53:03 matthewbrett Exp $
  
myclass = 'phido_99';
cvs_v   = mars_cvs_version(myclass);

% Default object structure; see also paramfields.m
defstruct = [];

if nargin < 1
  defstruct.cvs_version = cvs_v;
  o = class(defstruct, myclass, mardo_99, phido);
  others = [];
  return
end
if nargin < 2
  others = [];
end

% Deal with passed objects of this (or child) class
if isa(params, myclass)
  o = params;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  % (Moot at the moment, as there are no fields specific for this object)
  [p others] = mars_struct('split', others, defstruct);
  return
end

if nargin < 3
  [phido_o params] = phido([], params, 0);
end

% send design to mardo_99
[mardo_o others] = mardo_99(params, others);

% fill params with defaults, parse into fields for this object, children
[params, others] = mars_struct('ffillsplit', defstruct, others);

% add cvs tag
params.cvs_version = cvs_v;

% set the phido_99 object
o  = class(params, myclass, phido_o, mardo_o);

return