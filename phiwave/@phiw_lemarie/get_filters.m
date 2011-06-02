function [H,G,RH,RG] = get_filters(obj, dim, varargin)
% returns filters for lemarie wavelet  
% FORMAT [H,G,RH,RG] = get_filters(obj, dim, varargin)
% 
% Input
% obj       - phiw_lemarie object
% dim       - size of input to filter 
% varargin  - any other parameters used to determine filters (not
%             applicable for this object)
% 
% Returns
% H         - high pass analysis filter
% G         - low pass analysis
% RH        - high pass synthesis
% RG        - low pass synthesis
% 
% $Id: get_filters.m,v 1.1 2004/09/26 07:48:37 matthewbrett Exp $

if nargin < 2
  error('Need image width to specify filter')
end

f_len = ceil(dim/obj.dim_div/2)*2;
[H,G,RH,RG] = lemarie(f_len);