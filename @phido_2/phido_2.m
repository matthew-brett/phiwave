function [o, others] = phido_2(des, params, phido_o)
% class constructor for SPM2 phiwave design object
% FORMAT [o, others] = phido_2(des, params, phido_o)
%
% Inputs  
% des     - SPM design, which can be a mardo object, or another SPM design
%           format recognized by the mardo constructor - see help mardo for
%           details.
% params  - structure, containing extra fields for object (or parent)
% phido_o - (optional) phido object to inherit from
%
% Outputs
% o       - phido_2 object (unless disowned)
% others  - any unrecognized fields from params, for processing by
%           children
%
% This object may be called from the phido object contructor with a mardo
% and phido object as input.  phido_2 checks to see if the contained design
% is an SPM2 design, returns the object unchanged if not.  If it is an SPM2
% design, it claims ownership of the passed object.
%
% $Id: phido_2.m,v 1.2 2004/09/19 03:15:31 matthewbrett Exp $
  
myclass = 'phido_2';
defstruct = [];

if nargin < 1
  des = [];
end
if isa(des, myclass)
  o = des;
  return
end
if nargin < 2
  params = [];
end
if nargin < 3
  [phido_o params] = phido([], params, 0);
end
others = [];

% send design to mardo
o_params = params;
[mardo_o params] = mardo(des, params);

% if this is not a good design type for us, return
if ~strcmp(class(mardo_o), 'mardo_2')
  o      = des;
  others = o_params;
  return
end

% fill params with defaults, parse into fields for this object, children
[params, others] = mars_struct('ffillsplit', defstruct, params);

% add cvs tag
params.cvs_version = mars_cvs_version(myclass);

% set the phido_2 object
o  = class(params, myclass, mardo_o, phido_o);

return