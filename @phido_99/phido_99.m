function [o, others] = phido_99(des, params, phido_o)
% class constructor for SPM2 phiwave design object
% FORMAT [o, others] = phido_99(des, params, phido_o)
%
% Inputs  
% des     - SPM design, which can be a mardo_99 object, or another SPM99 design
%           format recognized by the mardo_99 constructor - see help mardo for
%           details.
% params  - structure, containing extra fields for object (or parent)
% phido_o - (optional) phido object to inherit from
%
% Outputs
% o       - phido_99 object (unless disowned)
% others  - any unrecognized fields from params, for processing by
%           children
%
% This object may be called from the phido object contructor with a mardo
% and phido object as input, or called directly.  The container makes no
% attempt to check if this is really an SPM99 design.
%
% $Id: phido_99.m,v 1.3 2004/09/19 03:35:51 matthewbrett Exp $
  
myclass = 'phido_99';
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

% send design to mardo_99
[mardo_o params] = mardo_99(des, params);

% fill params with defaults, parse into fields for this object, children
[params, others] = mars_struct('ffillsplit', defstruct, params);

% add cvs tag
params.cvs_version = mars_cvs_version(myclass);

% set the phido_99 object
o  = class(params, myclass, mardo_o, phido_o);

return