function y=iwtnd(wx,rh,rg,scales,tam,scales_levels,del1,del2) 

% IWTND Discrete Inverse N-D Wavelet Transform.
%
% IWTND (WX,RH,RG,SCALES) calculates the N-D inverse wavelet transform of
% vector WX, which should be a SCALES-scales direct wavelet transform. The
% second argument RH is the synthesis lowpass filter and the third argument
% RG the synthesis highpass filter.
%
% IWT will calculate the size of the reconstructed vector(s) the largest as
% possible (maybe 1 point larger than the original) unless it is provided
% using IWT(WX,RH,RG,SCALES,SIZ). A value of 0 for SIZ is the same as
% ommiting it.
%
% IWT can be used to perform a single process of multiresolution
% analysis. The way to do it is by selecting the scales whose highpass bands
% (detail signals) should be ignored for reconstruction.
%
% Using IWT(WX,RH,RG,SCALES,SIZ,SCALES_LEVELS) where SCALES_LEVELS is a
% SCALES-sized vector,1's or 0's. An i-th coefficient of 0 means that the
% i-th scale detail (starting from the deepest) should be
% ignored. SCALES_LEVELS vector can be replaced by a single number for
% selecting just only the SCALES_LEVELS deepest scales.
%
% An all-ones vector, or a single number equal to SCALES, is the same as the
% normal inverse transform.
%         
% IWT (WX,RH,RG,SCALES,SIZ,SCALES_LEVELS,DEL1,DEL2) calculates the inverse
% transform or performs the multiresolution analysis, but allowing the users
% to change the alignment of the outputs with respect to the input
% signal. This effect is achieved by setting to DEL1 and DEL2 the analysis
% delays of H and G respectively, and calculating the complementary delays
% for synthesis filters RH and RG. The default values of DEL1 and DEL2 are
% calculated using the function WTCENTER.
%
% See also: WT, WT2D, WTCENTER, WTMETHOD
%
% Based on iwt.m from UviWave 3.0, with thanks - see below
%
% $Id: iwtnd.m,v 1.1 2004/07/01 23:46:25 matthewbrett Exp $

% Restrictions:
%
%   - Synthesis filters from the same set as in analysis must be used.
%     If forced delays were used in analysis, the same delays should
%     be forced in synthesis (iwt calculates the complementary ones), 
%     so as to get a perfect vector reconstruction (or the equivalent 
%     in the case of not full reconstruction).
%
%   - The number of scales indicated in SCALES, must match the number of 
%     them specified in the analysis process. Otherwise, the 
%     reconstruction will be absolutely erroneous. The same is
%     applied to the original vector size SIZ, but if it's not given,
%     or it's set to zero, IWT will give the recostructed vector the
%     largest size as possible.
%


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

% -----------------------------------
%    CHECK PARAMETERS AND OPTIONS
% -----------------------------------

rh=rh(:)';	% Arrange the filters so that they are row vectors.
rg=rg(:)';

% matrix dimensions
dims = size(wx);
n_dims = ndims(wx);

if nargin<6, 	% SCALES_LEVELS not given means reconstructing all bands.
  scales_levels=scales;
end;

% If SCALES_LEVELS specifies the number of scales then build the
% SCALES_LEVELS vector with SCALES_LEVELS ones and SCALES-SCALES_LEVELS
% zeros.
if prod(size(scales_levels))==1
  scales_levels=[ones(1, scales_levels) ...
		 zeros(1, scales - scales_levels)];
else
  % Make sure that SCALES_LEVELS is SCALES elements long.
  if length(scales_levels)~=scales,	
    disp('SCALES_LEVELS should be a Single number (<=SCALES) or a vector with SCALES elements');
    return;
  end;
  
  % And make sure that all nonzero elements in SCALES_LEVELS are ones
  scales_levels(scales_levels~=0) = 1;
end;

% ----------------------------------
%    CHECK THE ORIGINAL LENGTH
% ----------------------------------

% If no original size is given, set it to 'unknown'.
if (nargin<5)			
  tam=0;
end
if prod(size(tam)) == 1
  tam = ones(1, n_dims) * tam;
end

lo = ones(n_dims, scales+1);
for d = 1:n_dims
  if dims(d)==1, continue, end
  tam_d = tam(d);
  % If the original size is unknown the maximum possible will be set.
  if tam_d==0,			
    tam_d=maxrsize(dims(d), scales);	
    if tam_d==0,
      error(['Can''t determine the original length.' ...
	    'SCALES might be wrong']);
    end
  end
  % Keep in a vector the succesive sizes of the wavelet bands.
  lo(d,1)=tam_d; 			
  for i=1:scales, 			
    lo(d, i+1)=floor((lo(d, i)+1)/2);	
  end
  
  % Check the given size, arrange if possible (the error can be in SCALES)
  if dims(d)~=sum(lo(d, 2:scales+1))+lo(d, scales+1),	
    tam_d=maxrsize(dims(d),scales);
    fprintf(1,'\nThe given size is not correct. Trying default size: ');
    fprintf(1,'%u\n',tam_d);
    if tam_d==0,	
      disp('No default size found. SCALES might be wrong');
      return;
    end;
    lo(d, 1)=tam_d; 
    for i=1:scales, 
      lo(d, i+1)=floor((lo(d, i)+1)/2);	
    end
    % If the default size is bad too, exit.
    if dims(d)~=sum(lo(d, 2:scales+1))+lo(d, scales+1),	
      disp('Default failed. SCALES might be wrong');
      return
    end;
    fprintf(1,'(Checscales the result, may be wrong. If so, ckeck SCALES)\n');
  end
end

%--------------------------
%    DELAY CALCULATION 
%--------------------------

llp=length(rh);		% Length of the lowpass filter.
lhp=length(rg);		% Length of the highpass filter.


% The total delay of the analysis-synthesis process must match the sum of
% the analysis delay plus the synthesis delay. SUML holds this total delay,
% which is different depending on the kind of filters.
suml = llp+lhp-2;		
difl = abs(lhp-llp);		
if rem(difl,2)==0		
  suml = suml/2;		
end;				

% Calculate analysis delays as the reciprocal M. C.
dlpa=wtcenter(rg);
dhpa=wtcenter(rh);

% difference between them must be even
if rem(dhpa-dlpa,2)~=0		
  dhpa=dhpa+1;		
end

% Other experimental filter delays can be forced from the arguments,
if nargin==8,			
  dlpa=del1;		
  dhpa=del2;	
end

% Found the analysis delays, the synthesis are the total minus the analysis
% ones.
dlp = suml - dlpa;		
dhp = suml - dhpa;

%------------------------------
%    WRAPPAROUND CALCULATION 
%------------------------------

% The number of samples for the wrapparound.
L=max([llp,lhp,dhp,dlp]);	
							
%------------------------------
%     START THE ALGORITHM 
%------------------------------

shift_dims = [2:n_dims 1];
y = wx;

for sc=1:scales

  % get new data block containing lowpass + highpass bits of vector
  proc_scale = scales+1-sc;
  t_sz = lo(:, proc_scale);
  if sc == scales
    w = y;
  else
    % following assumes UviWave ordering
    switch n_dims
     case 2
      w = y(1:t_sz(1), 1:t_sz(2));
     case 3
      w = y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3));
     case 4
      w = y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3), 1:t_sz(4));
     otherwise
      error('Not implemented');
    end
  end
  
  for d = 1:n_dims
    
    % Transform X dimension of matrix
    lx=size(w, 1);
    
    if lx > 1  % only transform dims of size > 1

      % 1 - The lowpass vector... interpolate it ending with a '0' so that
      % the wraparound doesn't put two samples toghether.  The input signal
      % can be smaller than L, so it can be necessary to repeat the
      % wraparound several times
      wrap_repeats = ceil(L/lx);
      wrap_indices = repmat(1:lx, 1, wrap_repeats);
      wrap_b = wrap_indices(end-L+1:end);
      wrap_e = wrap_indices(1:L);
      
      lp_inds = 1:lx/2;
      hp_inds = lx/2+1:lx;
      dat_inds = 1:2:lx;
      yl = zeros(size(w));
      switch n_dims
       case 2
	yl(dat_inds, :) = w(lp_inds, :);
	yl=[yl(wrap_b, :); yl; yl(wrap_e, :)];
       case 3
	yl(dat_inds, :, :) = w(lp_inds, :, :);
	yl=[yl(wrap_b, :, :); yl; yl(wrap_e, :, :)];
       case 4
	yl(dat_inds, :, :, :) = w(lp_inds, :, :, :);
	yl=[yl(wrap_b, :, :, :); yl; yl(wrap_e, :, :, :)];
       otherwise
	error('Not implemented');
      end
      
      % Process the highpass band only if SCALES_LEVELS specifies to do so.
      if (scales_levels(sc)~=0)		
	
	yh = zeros(size(w));
	switch n_dims
	 case 2
	  yh(dat_inds, :) = w(hp_inds, :);
	  yh=[yh(wrap_b, :); yh; yh(wrap_e, :)];
	 case 3
	  yh(dat_inds, :, :) = w(hp_inds, :, :);
	  yh=[yh(wrap_b, :, :); yh; yh(wrap_e, :, :)];
	 case 4
	  yh(dat_inds, :, :, :) = w(hp_inds, :, :, :);
	  yh=[yh(wrap_b, :, :, :); yh; yh(wrap_e, :, :, :)];
	 otherwise
	  error('Not implemented');
	end
      end
    
      % Do the lowpass systhesis filtering and leave out the filter delays and
      % the wraparound.
      
      % Make into vector - it's slightly faster even for long L
      % maybe due to cache blocking
      sz = size(yl);
      yl = yl(:);
      
      % Then do lowpass filtering ...
      yl=filter(rh, 1, yl);	       	
      
      % Reshape to matrix
      yl = reshape(yl, sz);
      
      % put back into outputs leaving out wraparound, filter delays
      dec_indices = (dlp+1+L):1:(dlp+L+lx);
      switch n_dims
       case 2 
	yl=yl(dec_indices, :);    
       case 3 
	yl=yl(dec_indices, :, :);    
       case 4 
	yl=yl(dec_indices, :, :, :);    
       otherwise
	error('Not implemented');
      end
      
      % If necessary, do the same with highpass.
      if (scales_levels(sc)~=0)		
	yh = yh(:);
	yh=filter(rg, 1, yh);	       	
	yh = reshape(yh, sz);
	dec_indices = (dlp+1+L):1:(dlp+L+lx);
	switch n_dims
	 case 2 
	  yh=yh(dec_indices, :);    
	 case 3 
	  yh=yh(dec_indices, :, :);    
	 case 4 
	  yh=yh(dec_indices, :, :, :);    
	 otherwise
	  error('Not implemented');
	end 
	% Sum the two outputs if we've reconstructed high-pass
	w=yl+yh;		
      else 
	% or get only the lowpass side.
	w=yl;			
      end;
      
      % I found this code in iwt, but can't understand how this extra
      % zero can be added
% $$$     lx=size(w, 1);
% $$$     % If the added '0' was not needed
% $$$     if lx>lo(d, proc_scale)
% $$$       w=w(1:lx-1);	% pick it out now, not before.
% $$$       lx=lx-1;	% (this reduces the next length)
% $$$     end
    end % if lx > 1
    
    % move next dimension to X
    w = permute(w, shift_dims);
    
  end % for dim 
  
  % set data block into output
  if sc == scales
    y = w;
  else
    % following assumes UviWave ordering
    switch n_dims
     case 2
      y(1:t_sz(1), 1:t_sz(2)) = w;
     case 3
      y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3)) = w;
     case 4
      y(1:t_sz(1), 1:t_sz(2), 1:t_sz(3), 1:t_sz(4)) = w;
     otherwise
      error('Not implemented');
    end    
  end

end % for scale

%------------------------------
%    END OF THE ALGORITHM 
%------------------------------

