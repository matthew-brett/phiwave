function [H,G,RH,RG] = filters(obj, varargin)
% returns filters for template wavelet  
%
% $Id: filters.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

w = obj.params;
[H,G,RH,RG] = deal(w.H,w.G,w.RH,w.RG);