function w = width(obj, varargin)
% an estimate of the effective width of wavelet filter
% FORMAT w = width(obj, varargin)
% 
% Intended to give number of points over which the lowpass filter has
% important power
%
% Inputs 
% obj         - input wavelet object
% varargin    - any other necessary args to wavelet filter
% 
% Ouputs
% w           - estimated width in datapoints
% 
% $Id: width.m,v 1.2 2005/06/05 04:21:27 matthewbrett Exp $
  
[tmp G] = get_filters(obj, varargin{:});

% Get 2.5 97.5 centile range of density of squared coefficients 
% (seemed like a good idea at the time)
dens = cumsum(G.^2);
dens = dens / dens(end);
in_d = find(dens > 0.025 & dens < 0.975);
if isempty(in_d)
  w = 1;
else
  w = in_d(end) - in_d(1) + 1;
end