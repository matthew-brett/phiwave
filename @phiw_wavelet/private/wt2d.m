function y=wt2d(x,h,g,scales,del1,del2)
% WT2D   Two dimensional Wavelet Transform. 
%
% See wtnd for help on inputs and output format 
% 
% This function is a wrapper for wtnd, for compatibility with UviWave
%
% See also:  WTND, IWT, IWTND, WTCENTER, ISPLIT.
%
% $Id: wt2d.m,v 1.3 2004/07/15 21:23:26 matthewbrett Exp $

if nargin < 3
  error('Need data to transform and two filters');
end
if nargin < 4
  scales = [];
end
if nargin < 5
  del1 = [];
end
if nargin < 6
  del2 = [];
end

n_dims = ndims(x);
p_dims = [1 1 zeros(1, n_dims-2)];
  
if n_dims > 2
  warning('wt2d does a 2D transform; use wtnd for N-D transforms');
end
y = wtnd(x, h, g, scales, del1, del2, p_dims);