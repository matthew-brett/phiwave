function y=wtnd(x,h,g,scales,del1,del2)
% wtnd - Discrete N-D Wavelet Transform.
% 
% WTND(X,H,G,SCALES) calculates the N-D wavelet transform of matrix X, where
% N is the number of dimensions of X.  The second argument H is the lowpass
% filter and the third argument G the highpass filter.  WTND generalizes
% the algorithm for UviWave WT to N dimensions.
%
% WTND(X,H,G,SCALES,DEL1,DEL2) calculates the N-D wavelet transform of matrix
% X, but also allows the user to change the alignment of the outputs with
% respect to the input signal. This effect is achieved by setting to DEL1
% and DEL2 the delays of H and G respectively. The default values of DEL1
% and DEL2 are calculated using the function WTCENTER.
%
%      See also:  IWT, WT2D, IWT2D, WTCENTER, ISPLIT.
%
% Based on wt.m from UviWave 3.0, with thanks - see below
%
% $Id: wtnd.m,v 1.3 2004/07/13 01:51:07 matthewbrett Exp $


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
% the X dimension, then filtering.  Filtering done by making image into a
% vector and filtering the vector.  This can result in a lot of redundant
% computation (across X lines) but, probably because of efficient use of the
% cache by the matlab/ATLAS code, it is still faster than filtering line by
% line. The algorithm goes up to 4D, but could be extended further using
% subsref commands [n_dims = 2; subsref(c, struct('type', '()', 'subs',
% repmat({:}, 1, n_dims)))]; I haven't used these here because they can be
% considerably slower than direct [c(:,:)] type referencing
  
% -----------------------------------
%    CHECK PARAMETERS AND OPTIONS
% -----------------------------------

if nargin < 3
  error('Need at least matrix to wt, and wt filters');
end
if nargin < 4
  scales = [];
end

% get output and scales dimensions 
dims   = size(z);
n_dims = length(dims);
[wt_sz sc_in_sz sc_out_sz] = wt_dims(dims, scales);

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
if nargin==5, error('Need two delays, if specified'); end
if nargin==6,		
  dlp=del1;		
  dhp=del2;
end;

%------------------------------
%    WRAPPAROUND CALCULATION 
%------------------------------
llp=length(h);                	% Length of the lowpass filter
lhp=length(g);                	% Length of the highpass filter.

%------------------------------
%     START THE ALGORITHM 
%------------------------------

n_dims = ndims(x);
shift_dims = [2:n_dims 1];
t = x;
t_sz = dims;

% For every scale (iteration)...
for sc=1:scales			
  % get new data block
  if sc > 1
    t_sz(dims > 1) = t_sz(dims > 1) / 2;
    % following assumes UviWave ordering
    switch n_dims
      case 2
       t = y(1:t_sz(1), 1:t_sz(2));
      case 3
       t = y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3));
      case 4
       t = y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3), 1:t_sz(4));
     otherwise
       error('Not implemented');
    end
  end
  
  for d = 1:n_dims
  
    % Transform X dimension of matrix
    lx=size(t, 1);
    
    if lx > 1  % do not transform dims of size 1
    
      t = do_wtx(t, h, g, dlp, dhp);
    
    end % if lx > 1
    
    % move next dimension to X
    t = permute(t, shift_dims);
  end

  % set data block into output
  if sc == 1
    y = t;
  else
    % following assumes UviWave ordering
    switch n_dims
     case 2
      y(1:t_sz(1), 1:t_sz(2)) = t;
     case 3
      y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3)) = t;
     case 4
      y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3), 1:t_sz(4)) = t;
     otherwise
      error('Not implemented');
    end    
  end
    
end

%------------------------------
%    END OF THE ALGORITHM 
%------------------------------

