function [o, others] = phiw_daub(num_coeffs, others)
% class constructor for phiw_daub object
% FORMAT [o, others] = phiw_daub(num_coeffs, others)
% inherits from phiw_wavelet
% 
% Synopsis
% --------
% o = phiw_daub(4);
% 
% Inputs
% num_coeffs - a scalar, setting the number of coefficients for the
%             Daubechies wavelet filter
% others    - optional structure with any other fields for phiw_wavelet
%             (see phiw_wavelet) 
% 
% $Id: phiw_daub.m,v 1.5 2005/06/05 04:42:22 matthewbrett Exp $

myclass = 'phiw_daub'; 

% Default object structure; Daub filter with 4 coefficients
defstruct = struct('num_coeffs', 4);

if nargin < 1
  
  num_coeffs  = [];
end
if nargin < 2
  others = [];
end

if isa(num_coeffs, myclass)
  o = num_coeffs;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  [p others] = mars_struct('split', others, defstruct);
  if isfield(p, 'num_coeffs'), o = num_coeffs(o, p.num_coeffs); end
  return
end

% Check num_coeffs input argument
if isempty(num_coeffs), num_coeffs = defstruct.num_coeffs; end
if ~isnumeric(num_coeffs) | prod(size(num_coeffs)) > 1
  error('num_coeffs argument should be a scalar');
end

% set the phiw_wavelet object
[H G RH RG] = daub(num_coeffs);
[phiw_w others] = phiw_wavelet(struct('H',  H, ...
				      'G',  G, ...
				      'RH', RH, ...
				      'RG', RG), ...
			       others);

% Return phiw_daub object
params.num_coeffs = num_coeffs;
o  = class(params, myclass, phiw_w);

