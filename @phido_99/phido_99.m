function [o, others] = phido_99(des, params)
% class constructor for SPM99 phiwave design object
% FORMAT [o, others] = phido_99(des, params)
%
% Inputs 
% des     - SPM design, which can be a mardo object, or another SPM
%           design format recognized by the mardo constructor - see help mardo for
%           details.
% params  - structure, containing extra fields for object (or parent)
%
% Outputs
% o       - phido_99 object (unless disowned)
% others  - any unrecognized fields from params, for processing by
%           children
%
% This object is called from the phido object contructor
% with a phido object as input.  phido_99 checks to see
% if the contained design is an SPM99 design, returns
% the object unchanged if not.  If it is an SPM99
% design, it claims ownership of the passed object.
%
% $Id: phido_99.m,v 1.1 2004/09/16 06:19:39 matthewbrett Exp $
  
myclass = 'phido_99';
defstruct = [];

if nargin < 1
  des = [];
end
if nargin < 2
  params = [];
end
others = [];

if isa(des, myclass)
  o = des;
  return
end
    
% normal call is via phido constructor
if isa(des, 'phido')
  % Check to see if this is a suitable design, return if not
  if ~strcmp(type(des), 'spm99'), o = des; return, end
  uo = des;
  des = [];
else
  uo = [];
end

% fill with defaults
params = mars_struct('ffillmerge', defstruct, params);

if ~isa(uo, 'phido') % phido object not passed
  % umbrella object, parse out fields for (this object and children)
  % second argument of 0 prevents recursive call back to here
  [uo, params] = phido(des, params, 0);
end

% reparse parameters into those for this object, children
[params, others] = mars_struct('split', params, defstruct);

% add cvs tag
params.cvs_version = mars_cvs_version(myclass);

% set the phido object
o  = class(params, myclass, uo);

return