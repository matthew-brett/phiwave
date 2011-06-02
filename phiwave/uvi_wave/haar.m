function [h,g,rh,rg]=haar(varargin)
% returns coefficients for Haar wavelet tranform
% FORMAT [h,g,rh,rg]=haar(varargin)
% 
% Where varargin(s) are ignored and
% 
% h       - low-pass synthesis
% g       - high-pass synthesis
% rh      - low-pass analysis
% rg      - high-pass analysis
% 
% $Id: haar.m,v 1.1 2005/07/07 16:34:56 matthewbrett Exp $
  
[rh,rg,h,g]=rh2rg([1 1] ./ sqrt(2));
