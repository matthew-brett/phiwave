function y=wt(x,h,g,scales,del1,del2)

% WT   Discrete Wavelet Transform.
% 
%      WT(X,H,G,SCALES) calculates the wavelet transform of vector X. 
%      If X is a matrix (2D), WT will calculate the one dimensional 
%      wavelet transform of each row vector. The second argument H 
%      is the lowpass filter and the third argument G the highpass
%      filter.
%
%      The output vector contains the coefficients of the DWT ordered 
%      from the low pass residue at scale K to the coefficients
%      at the lowest scale, as the following example ilustrates:
%
%      Output vector (k=3):
%
%      [------|------|------------|------------------------]
%	  |	  |	   |		    |
%	  |	  |	   |		    `-> 1st scale coefficients 
% 	  |	  |	   `-----------> 2nd scale coefficients
%	  |	  `--------------------> 3rd scale coefficients
%	  `----------------> Low pass residue  at 3rd scale 
%
%       
%      If X is a matrix, the result will be another matrix with 
%      the same number of rows, holding each one its respective 
%      transformation.
%
%      WT (X,H,G,K,DEL1,DEL2) calculates the wavelet transform of 
%      vector X, but also allows the users to change the alignment
%      of the outputs with respect to the input signal. This effect
%      is achieved by setting to DEL1 and DEL2 the delays of H and
%      G respectively. The default values of DEL1 and DEL2 are 
%      calculated using the function WTCENTER. 
%
%      See also:  IWT, WT2D, IWT2D, WTCENTER, ISPLIT.
%
% $Id: wt.m,v 1.2 2004/07/15 04:25:06 matthewbrett Exp $

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
if n_dims == 2 & all(sz > 1)
  p_dims = [0 1];
else
  p_dims = ones(1, n_dims);
end

y = wtnd(x, h, g, scales, del1, del2, p_dims);