function y=iwt2d(wx,rh,rg,scales,tamx,tamy,sc_levels,del1,del2)
% IWT2D Two dimensional Inverse Wavelet Transform.
%
% See iwtnd and wtnd for help on inputs and output format 
% 
% This function is a wrapper for iwtnd, for compatibility with UviWave
%
% See also:  WTND, IWT, IWTND, WTCENTER, ISPLIT.
%
% $Id: iwt2d.m,v 1.2 2004/07/15 05:19:00 matthewbrett Exp $

if nargin < 4
  error('Need data to iwt, two filters and number of scales');
end
if nargin < 5
  tamx = [];
end
if nargin < 6
  tamy = [];
end
if nargin < 7
  sc_levels = [];
end
if nargin < 8
  del1 = [];
end
if nargin < 9
  del2 = [];
end

n_dims = ndims(wx);
p_dims = [1 1 zeros(1, n_dims-2)];
  
if n_dims > 2
  warning('iwt2d does a 2D transform; use wtnd for N-D transforms');
end

y = iwtnd(x, h, g, scales, [tamx tamy], sc_levels, del1, del2, p_dims);
