function y=iwt(wx,rh,rg,scales,tam,sc_levels,del1,del2)
% IWT  Discrete Inverse Wavelet Transform.
% 
% See iwtnd and wtnd for help on inputs and output format 
% 
% This function is a wrapper for iwtnd, for compatibility with UviWave
%
% See also:  WTND, WT, IWT, WTCENTER, ISPLIT.
%
% $Id: iwt.m,v 1.3 2004/07/15 05:19:00 matthewbrett Exp $

if nargin < 4
  error('Need data to iwt, two filters and number of scales');
end
if nargin < 5
  tam = [];
end
if nargin < 6
  sc_levels = [];
end
if nargin < 7
  del1 = [];
end
if nargin < 8
  del2 = [];
end

sz = size(wx);
n_dims = length(sz);
p_dims = zeros(n_dims);
if sz(2) > 1
  p_dims(2) = 1;
else 
  p_dims(1) = 1; 
end
  
if n_dims > 2
  warning('iwt does a 1D transform; use iwtnd for N-D transforms');
end
y = iwtnd(x, h, g, scales, tam, sc_levels, del1, del2, p_dims);