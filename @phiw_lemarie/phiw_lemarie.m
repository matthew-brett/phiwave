function [o, others] = phiw_lemarie(dim_div, others)
% class constructor for phiw_lemarie object
% FORMAT [o, others] = phiw_lemarie(dim_div, others)
% inherits from phiw_wavelet
% 
% Synopsis
% --------
% o = phiw_lemarie(2);
% 
% Inputs
% dim_div - a scalar, setting the width of the lemarie filter.  The
%             number is the number by which to divide the size of the
%             processed dimension, to get the filter width.  This number
%             is always used when getting the filters to use; the filters
%             are therefore not stored in the phiw_wavelet parent object
%        
% others    - optional structure with any other fields for phiw_wavelet
%             (see phiw_wavelet) 
% 
% $Id: phiw_lemarie.m,v 1.4 2005/06/05 04:42:22 matthewbrett Exp $

myclass = 'phiw_lemarie'; 

% Default object structure; Lemarie filter, dividing processed dimension
% size by 2 to get filter width
defstruct = struct('dim_div', 2);

if nargin < 1
  dim_div  = [];
end
if nargin < 2
  others = [];
end

if isa(dim_div, myclass)
  o = dim_div;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  [p others] = mars_struct('split', others, defstruct);
  if isfield(p, 'dim_div'), o = dim_div(p.dim_div); end
  return
end

% Check dim_div input argument
if isempty(dim_div), dim_div = defstruct.dim_div; end
if ~isnumeric(dim_div) | prod(size(dim_div)) > 1
  error('dim_div argument should be a scalar');
end

% set the phiw_wavelet object
[phiw_w others] = phiw_wavelet(struct('H',  [], ...
				      'G',  [], ...
				      'RH', [], ...
				      'RG', []), ...
			       others);

% Return phiw_lemarie object
params.dim_div = dim_div;
o  = class(params, myclass, phiw_w);

