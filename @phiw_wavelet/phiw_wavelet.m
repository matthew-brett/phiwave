function [o, others] = phiw_wavelet(params, others)
% phiw_wavelet - class constructor
% FORMAT [o, others] = phiw_wavelet(params, others)
%
% Synopsis
% --------
% o = phiw_wavelet;
% 
% % Imagine you have set variables H G RH RG to be analysis low, high pass
% % synthesis low, high pass filters respectively
% o = phiw_wavelet(struct('H', H, 'G', G, 'RH', RH, 'RG', RG));
% 
% Inputs [defaults]
%  params  - maybe a filter structure containing fields
%              H  - analysis low pass   [1]
%              G  - analysis high pass  [1]
%              RH - synthesis low pass  [1]
%              RG - synthesis high pass [1]
%            OR
%              structure containing params structure and any other object
%              fields (being, at present, only detail_right (see below))
%
% others   - optional structure with any other fields for the object
%            Fields can be 
%             - detail_right - flag, if == 1 specifies detail coeffs to
%                              right of vector (UviWave) [1]
%            OR
%            (if scalar) - interpreted as value for detail_right
%
% As usual, any unrecognized fields in input structures are passed out
% for other (child) objects to parse if they like
%
% $Id: phiw_wavelet.m,v 1.3 2004/09/24 19:25:51 matthewbrett Exp $

myclass = 'phiw_wavelet'; 
cvs_v   = mars_cvs_version(myclass);

% Default object structure
defstruct = struct('params', struct('H',1,'G',1,'RH',1,'RG',1),...
		   'detail_right', 1);

if nargin < 1
  defstruct.cvs_version = cvs_v;
  o = class(defstruct, myclass);
  others = [];
  return
end
if nargin < 2
  others = [];
end

% If others is scalar, assume it is value for detail_right
if isnumeric(others) & prod(size(others)) == 1
  others = struct('detail_right', others);
end
if ~isempty(others) & ~isstruct(others)
  error('"others" input should be scalar or struct');
end

if isa(params, myclass)
  o = params;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  [p others] = mars_struct('split', others, defstruct);
  if isfield(p, 'detail_right'), o.detail_right = p.detail_right; end
  return
end

% Check params input argument
if ~isfield(params, 'params'), params = struct('params', params); end

% fill with other params, defaults, parse into fields for this object,
% children
params = mars_struct('ffillmerge', params, others);
[params, others] = mars_struct('ffillsplit', defstruct, params);

% cvs version
params.cvs_version = cvs_v;

% set the phiw_wavelet object
o  = class(params, myclass);

return