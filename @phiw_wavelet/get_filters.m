function [H,G,RH,RG] = get_filters(obj, varargin)
% returns filters for template wavelet  
% FORMAT [H,G,RH,RG] = get_filters(obj, varargin)
% 
% Input
% obj       - phiw_wavelet object
% varargin  - any other parameters used to determine filters (not
%             applicable for phiw_wavelet base type, but for (e.g)
%             phiw_lemarie derived type)
% 
% Returns
% H         - high pass analysis filter
% G         - low pass analysis
% RH        - high pass synthesis
% RG        - low pass synthesis
% 
% $Id: get_filters.m,v 1.1 2004/09/26 03:53:27 matthewbrett Exp $

w = obj.filters;
[H,G,RH,RG] = deal(w.H,w.G,w.RH,w.RG);