function [H,G,RH,RG] = filters(w, varargin)
% returns filter for daub wavelet  
  
[H,G,RH,RG] = daub(w.phiw_wavelet.params);
