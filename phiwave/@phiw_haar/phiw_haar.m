function [o, others] = phiw_haar(params)
% class constructor for phiw_haar object
% FORMAT [o, others] = phiw_haar(params)
% inherits from phiw_wavelet
% 
% Synopsis
% --------
% o = phiw_haar;
% 
% Inputs
% params    - optional structure with any fields for phiw_wavelet
%             (see phiw_wavelet) 
% 
% $Id: phiw_haar.m,v 1.1 2005/07/07 21:24:47 matthewbrett Exp $

myclass = 'phiw_haar'; 

% Default object structure; dummy field, otherwise object creation
% doesn't work
defstruct = struct('haar_piece', []);

if nargin < 2
  params = [];
end

if isa(params, myclass)
  o = params;
  return
end

% set the phiw_wavelet object
[H G RH RG] = haar;
[phiw_w others] = phiw_wavelet(struct('H',  H, ...
				      'G',  G, ...
				      'RH', RH, ...
				      'RG', RG), ...
			       params);

% Return phiw_haar object
o = class(defstruct, myclass, phiw_w);

