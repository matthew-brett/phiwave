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
% $Id: wtnd.m,v 1.1 2004/06/28 15:49:19 matthewbrett Exp $


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

h=h(:)';	% Arrange the filters so that they are row vectors.
g=g(:)';

% matrix dimensions
dims = size(x);
if any(log2(dims)-floor(log2(dims)))
  error('Need dyadic dimensions');
end

% scale
min_sz = min(dims(dims > 1));
if min_sz<2^scales 
  disp('The scale is too high. The maximum for the signal is:')
  floor(log2(min_sz))
  return
end

%--------------------------
%    DELAY CALCULATION 
%--------------------------

% Calculate delays as the C.O.E. of the filters
dlp=wtcenter(h);
dhp=wtcenter(g);

if rem(dhp-dlp,2)~=0	% difference between them.
  dhp=dhp+1;		% must be even
end;

if nargin==6,		% Other experimental filter delays
  dlp=del1;		% can be forced from the arguments
  dhp=del2;
end;

%------------------------------
%    WRAPPAROUND CALCULATION 
%------------------------------
llp=length(h);                	% Length of the lowpass filter
lhp=length(g);                	% Length of the highpass filter.

% The number of samples for the wrapparound. Thus, we should need to move
% along any L samples to get the output wavelet vector phase equal to
% original input phase.
L=max([lhp,llp,dlp,dhp]);	

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
    
      % Build wrapparound. The input signal can be smaller than L, so it
      % can be necessary to repeat it several times
      wrap_repeats = ceil(L/lx);
      wrap_indices = repmat(1:lx, 1, wrap_repeats);
      wrap_b = wrap_indices(end-L+1:end);
      wrap_e = wrap_indices(1:L);
      
      % Add wraparound
      switch n_dims
       case 2
	t=[t(wrap_b, :); t; t(wrap_e, :)];
       case 3
	t=[t(wrap_b, :, :); t; t(wrap_e, :, :)];
       case 4
	t=[t(wrap_b, :, :, :); t; t(wrap_e, :, :, :)];
       otherwise
	error('Not implemented');
      end
      
      % Make into vector - it's slightly faster even for long L
      % maybe due to cache blocking
      sz = size(t);
      t = t(:);
      
      % Then do lowpass, highpass filtering ...
      yl=filter(h, 1, t);	       	
      yh=filter(g, 1, t); 
      
      % Reshape to matrix
      yl = reshape(yl, sz);
      yh = reshape(yh, sz);
      
      % Decimate the outputs, leaving out wraparound
      dec_indices = (dlp+1+L):2:(dlp+L+lx);
      switch n_dims
       case 2 
	yl=yl(dec_indices, :);    
	yh=yh(dec_indices, :);    
       case 3 
	yl=yl(dec_indices, :, :);    
	yh=yh(dec_indices, :, :);    
       case 4 
	yl=yl(dec_indices, :, :, :);    
	yh=yh(dec_indices, :, :, :);    
       otherwise
	error('Not implemented');
      end
      
      % Put the resulting wavelet step on its place into the wavelet
      % vector; generates UviWave ordering
      t =[yl; yh];
    
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

