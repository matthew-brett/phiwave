function [H,G,RH,RG] = filters(w, varargin)
% returns filter for lemarie wavelet  
%
% $Id: filters.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 2
  error('Need image width to specify filter')
end
  
[H,G,RH,RG] = lemarie(varargin{1}/w.phiw_wavelet.params);