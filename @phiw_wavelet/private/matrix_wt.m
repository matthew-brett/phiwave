function y=matrix_wt(x, h, g, p_dims, scales, del1, del2)
% matrix_wt - Discrete N-D Wavelet Transform.
% 
% MATRIX_WT(X,H,G,P_DIMS,SCALES) calculates the N-D wavelet transform of
% matrix X, where N is the number of dimensions of X.  The second argument H
% is the lowpass filter and the third argument G the highpass filter.
% P_DIMS is a matrix of flag values, one value per dimension of x; each
% dimension with a flag value of 1 is wt'ed.  Dimensions of size 1 are of
% course igmored.  MATRIX_WT generalizes the algorithm for UviWave WT to N
% dimensions.
% 
%
% MATRIX_WT(X,H,G,P_DIMS,SCALES,DEL1,DEL2) calculates the N-D wavelet
% transform of matrix X, but also allows the user to change the alignment of
% the outputs with respect to the input signal. This effect is achieved by
% setting to DEL1 and DEL2 the delays of H and G respectively. The default
% values of DEL1 and DEL2 are calculated using the function WTCENTER.
%
%      See also:  IWT, WT2D, IWT2D, WTCENTER, ISPLIT.
%
% Based in part on wt.m from UviWave 3.0, with thanks - see below
%
% $Id: matrix_wt.m,v 1.2 2004/07/13 06:37:09 matthewbrett Exp $

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

sz     = size(x);
n_dims = length(sz);

if nargin < 4
  p_dims = [];
end
if isempty(p_dims)
  p_dims = ones(1, n_dims);
end
if prod(size(p_dims))==1
  p_dims = ones(1, n_dims) * p_dims;
end
p_dims = p_dims & sz > 1;
if ~any(p_dims)
  y = x;
  return
end
if nargin < 5
  scales = [];
end

% get output and scales dimensions 
[wt_sz sc_in_sz sc_out_sz scales] = wt_dims(sz, scales, p_dims);

% Arrange the filters so that they are row vectors.  
h=h(:)';	
g=g(:)';

%--------------------------
%    DELAY CALCULATION 
%--------------------------

% Calculate delays as the C.O.E. of the filters
dlp=wtcenter(h);
dhp=wtcenter(g);

if rem(dhp-dlp,2)~=0	% difference between them.
  dhp=dhp+1;		% must be even
end;

% Other experimental filter delays can be forced from the arguments
if nargin==6, error('Need two delays, if specified'); end
if nargin==7,		
  dlp=del1;		
  dhp=del2;
end;

%------------------------------
%    WRAPPAROUND CALCULATION 
%------------------------------
llp=length(h);                	% Length of the lowpass filter
lhp=length(g);                	% Length of the highpass filter.

% Offsets
offsets = wt_sz - sz;

%------------------------------
%     START THE ALGORITHM 
%------------------------------

% For doing tricksy permute thing in loop below
shift_dims = [2:n_dims 1];

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
  
  for d = 1:n_dims

    % all the hard work is in C
    if p_dims(d)
      t = do_wtx(t, h, g, dlp, dhp);
    end 
    
    % move next dimension to X
    t = permute(t, shift_dims);
  end

  % reset offsets
  out_sz = sc_out_sz(sc, :);
  offsets = offsets - (out_sz - in_sz);
  op1 = offsets + 1;
  
  % set data block into output
  if ~(any(offsets)) % for speed, do the simplest case 
    if sc == 1
      y = t;
    else
      
      % following assumes UviWave ordering
      switch n_dims
       case 2
	y(1:out_sz(1), 1:out_sz(2)) = t;
       case 3
	y(1:out_sz(1), 1:out_sz(2), 1:out_sz(3)) = t;
       case 4
	y(1:out_sz(1), 1:out_sz(2), 1:out_sz(3), 1:out_sz(4)) = t;
       otherwise
	error('Not implemented');
      end    
    end
  else % more general case when there are offsets
    
    % following assumes UviWave ordering
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

