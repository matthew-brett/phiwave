function [y, scales] = wtnd(x, h, g, scales, del1, del2, p_dims)
% wtnd - Discrete N-D Wavelet Transform.
% 
% WTND(X,H,G,SCALES) calculates the N-D wavelet transform of matrix X,
% where N is the number of dimensions of X.  The second argument H is the
% lowpass filter and the third argument G the highpass filter.  WTND
% generalizes the algorithm for UviWave WT to N dimensions.
% 
% WTND(X,H,G,SCALES,DEL1,DEL2) calculates the N-D wavelet
% transform of matrix X, but also allows the user to change the alignment of
% the outputs with respect to the input signal. This effect is achieved by
% setting to DEL1 and DEL2 the delays of H and G respectively. The default
% values of DEL1 and DEL2 are calculated using the function WTCENTER.
%
% WTND(X,H,G,SCALES,DEL1,DEL2,P_DIMS) adds the ability to wt over a subset
% of the matrix dimensions.  P_DIMS should be a matrix of flag values,
% one value per dimension of X; each dimension with a flag value of 1 is
% wt'ed, dimensions of size 1 or with a 0 flag value are ignored.
% 
% Returns
% Y           - transformed matrix
% SCALES      - number of scales transformed
%               (SCALES can be set in routine if not passed as input)
% 
%      See also:  IWT, WT2D, IWT2D, WTCENTER, ISPLIT.
%
% Based in part on wt.m from UviWave 3.0, with thanks - see below
%
% $Id: wtnd.m,v 1.4 2004/07/14 20:31:54 matthewbrett Exp $

%--------------------------------------------------------
% Copyright (C) 1994, 1995, 1996, by Universidad de Vigo 
%                                                      
%                                                      
% Uvi_Wave is free software; you can redistribute it and/or modify it      
% under the terms of the GNU General Public License as published by the    
% Free Software Foundation; either version 2, or (at your option) any      
% later version.                                                           
%                                                                          
% Uvi_Wave is distributed in the hope that it will be useful, but WITHOUT  
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or    
% FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License    
% for more details.                                                        
%                                                                          
% You should have received a copy of the GNU General Public License        
% along with Uvi_Wave; see the file COPYING.  If not, write to the Free    
% Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.             
%                                                                          
%      Authors: Sergio J. Garcia Galan 
%               Cristina Sanchez Cabanelas 
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------

% Do the wt by iteratively switching matrix dimension to be processed to be
% the X dimension (columns), then filtering. The algorithm goes up to 4D,
% but could be extended further using subsref commands [n_dims = 2;
% subsref(c, struct('type', '()', 'subs', repmat({:}, 1, n_dims)))]; I
% haven't used these here because they can be considerably slower than
% direct [c(:,:)] type referencing
  
% -----------------------------------
%    CHECK PARAMETERS AND OPTIONS
% -----------------------------------

if nargin < 3
  error('Need at least matrix to wt, and wt filters');
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
if xor(isempty(del1), isempty(del2))
  error('You cannot specify only one of the two delays'); 
end
if nargin < 7
  p_dims = [];
end

% ------------------------
% Process input parameters
% ------------------------

% Input image dimensions
sz     = size(x);
n_dims = length(sz);

% Process p_dims 
def_pdims = ones(1, n_dims);
p_d_l = prod(size(p_dims));
if p_d_l == 0  % empty
  p_dims = def_pdims;
elseif p_d_l == 1
  p_dims = def_pdims * p_dims;
elseif p_d_l < n_dims
  p_dims = [p_dims(:)' ones(1, n_dims-p_d_l)];
elseif p_d_l > n_dims
  error('p_dims array has too many values for passed matrix');
end
p_dims = p_dims & sz > 1;
if ~any(p_dims), y = x;  return, end
n_p_dims = sum(p_dims);

% make filters into cells, and expand to N-D if necessary
if ~iscell(h), h = {h}; end
if prod(size(h))==1, h = repmat(h, 1, n_p_dims); end
if ~iscell(g), g = {g}; end
if prod(size(g))==1, g = repmat(g, 1, n_p_dims); end

%--------------------------
%    DELAY CALCULATION 
%--------------------------

if isempty(del1)
  % Calculate delays as the C.O.E. of the filters
  for d = 1:n_p_dims
    dlp(d) = wtcenter( h{d} );
    dhp(d) = wtcenter( g{d} );
  end
  % difference between them must be even
  dhp = dhp + (rem(dhp-dlp,2)~=0);	
else
  % Other experimental filter delays can be forced from the arguments
  o = ones(1, n_p_dims);
  dlp=del1; if prod(size(dlp))==1, dlp = o * dlp; end
  dhp=del2; if prod(size(dhp))==1, dhp = o * dhp; end
end

% get output and scales dimensions 
[wt_sz sc_in_sz sc_out_sz scales] = wt_dims(sz, scales, p_dims);

% Offsets
offsets = wt_sz - sz;

%------------------------------
%     START THE ALGORITHM 
%------------------------------

% For doing tricksy permute thing in loop below (see help wt_dim_shifts)
[shifts end_shift] = wt_dim_shifts(p_dims);
dims = [1:n_dims]';

% t is the input matrix to be wt'ed
t = x;

% y is the output matrix
y = zeros(wt_sz(:)');

% For every scale (iteration)...
for sc=1:scales			
  % get new data block
  in_sz = sc_in_sz(sc, :);
  if sc > 1
    % following assumes UviWave ordering
    switch n_dims
     case 2
      t = t(1:in_sz(1), 1:in_sz(2));
     case 3
      t = t(1:in_sz(1), 1:in_sz(2), 1:in_sz(3));
     case 4
      t = t(1:in_sz(1), 1:in_sz(2), 1:in_sz(3), 1:in_sz(4));
     otherwise
      error('Not implemented - but go ahead and do it if you need it');
    end
  end
  
  for d = 1:n_p_dims

    % move next dimension to X
    s = shifts(d);
    if s, t = permute(t, circshift(dims, s)); end
    
    % all the hard work is in C
    t = do_wtx(t, h{d}, g{d}, dlp(d), dhp(d));
    
  end

  % and back to original shape
  if end_shift
    t = permute(t, circshift(dims, end_shift));
  end
  
  % reset offsets
  out_sz = sc_out_sz(sc, :);
  offsets = offsets - (out_sz - in_sz);
  op1 = offsets + 1;
  
  % set data block into output
  % following assumes UviWave ordering
  if sc == 1 & ~any(offsets)  % for speed, do the simplest case 
    y = t;
  else
    switch n_dims
     case 2
      y(op1(1):out_sz(1) + offsets(1), ...
	op1(2):out_sz(2) + offsets(2)) = t;
     case 3
      y(op1(1):out_sz(1) + offsets(1), ...
	op1(2):out_sz(2) + offsets(2), ...
	op1(3):out_sz(3) + offsets(3)) = t;
     case 4
      y(op1(1):out_sz(1) + offsets(1), ...
	op1(2):out_sz(2) + offsets(2), ...
	op1(3):out_sz(3) + offsets(3), ...
	op1(4):out_sz(4) + offsets(4)) = t;
     otherwise
      error('Not implemented');
    end    
  end
end

%------------------------------
%    END OF THE ALGORITHM 
%------------------------------

