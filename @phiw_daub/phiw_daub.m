function [o, others] = phiw_daub(params, others)
% phiw_daub - class constructor
% FORMAT [o, others] = phiw_daub(params, others)
% inherits from phiw_wavelet
% 
% Synopsis
% --------
% o = phiw_daub(4);
% 
% Inputs
% params    - maybe a scalar, setting the number of coefficients for the
%             Daubechies wavelet filter
%             OR
%             structure containing params field as above and values for
%             any other object field for this object or parent (see
%             phiw_wavelet for details)
% others    - optional structure with any other fields for the object
%             (see phiw_wavelet) 
% 
% $Id: phiw_daub.m,v 1.3 2004/09/26 03:56:50 matthewbrett Exp $

myclass = 'phiw_daub'; 
cvs_v   = mars_cvs_version(myclass);

% Default object structure; Daub filter with 4 coefficients
defstruct = struct('num_coeffs', 4);

if nargin < 1
  params  = [];
end
if nargin < 2
  others = [];
end

if isa(params, myclass)
  o = params;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  % (There aren't any for now, so just sort out input args)
  [p others] = mars_struct('split', others, defstruct);
  if isfield(p, 'num_coeffs'), o = num_coeffs(o, p.num_coeffs), end
  return
end

% Check params input argument
if isempty(params), params = defstruct; end
if ~isfield(params, 'num_coeffs'), params = struct('num_coeffs', params); end
n_c = mars_struct('getifthere', params, 'num_coeffs');
if isempty(n_c)
  error('Need params field in input struct, or scalar');
end
if ~isnumeric(n_c) | prod(size(n_c)) > 1
  error('params argument should be a scalar');
end

params.cvs_version = cvs_v;

% set the phiw_wavelet object
[phiw_w others] = phiw_wavelet(params, others);
[o, others  = class(params, myclass);

