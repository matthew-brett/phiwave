function [H,G,RH,RG] = filters(w, varargin)
% returns filter for lemarie wavelet  
%
% $Id: filters.m,v 1.2 2004/07/14 20:33:09 matthewbrett Exp $

if nargin < 2
  error('Need image width to specify filter')
end

f_len = ceil(varargin{1}/w.phiw_wavelet.params/2)*2;
[H,G,RH,RG] = lemarie(f_len);