function y=wt(x,h,g,scales,del1,del2)
% WT   Discrete Wavelet Transform.
% 
% See wtnd for help on inputs and output format 
% 
% This function is a wrapper for wtnd, for compatibility with UviWave
%
% See also:  WTND, IWT, IWTND, WTCENTER, ISPLIT.
%
% $Id: wt.m,v 1.3 2004/07/15 05:19:00 matthewbrett Exp $

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

sz = size(x);
n_dims = length(sz);
p_dims = zeros(n_dims);
if sz(2) > 1
  p_dims(2) = 1;
else 
  p_dims(1) = 1; 
end
  
if n_dims > 2
  warning('wt does a 1D transform; use wtnd for N-D transforms');
end
y = wtnd(x, h, g, scales, del1, del2, p_dims);