function y=iwt(wx,rh,rg,scales,tam,sc_levels,del1,del2)
% IWT  Discrete Inverse Wavelet Transform.
% 
%        IWT (WX,RH,RG,SCALES) calculates the 1D inverse wavelet transform
%        of vector WX, which should be a SCALES-scales direct wavelet
%        transform. If WX is a matrix, then it's supposed to hold a wavelet
%        transform vector in each of its rows, and every one of them will be
%        inverse transformed. The second argument RH is the synthesis
%        lowpass filter and the third argument RG the synthesis highpass
%        filter.
%
%        IWT will calculate the size of the reconstructed vector(s) the
%        largest as possible (maybe 1 point larger than the original) unless
%        it is provided using IWT(WX,RH,RG,SCALES,SIZ). A value of 0 for SIZ
%        is the same as ommiting it.
%
%
%        IWT can be used to perform a single process of multiresolution
%        analysis. The way to do it is by selecting the scales whose
%        highpass bands (detail signals) should be ignored for
%        reconstruction.
%
%        Using IWT(WX,RH,RG,SCALES,SIZ,SC_LEVELS) where SC_LEVELS is a
%        SCALES-sized vector, 1's or 0's. An i-th coefficient of 0 means
%        that the i-th scale detail (starting from the deepest) should be
%        ignored. SC_LEVELS vector can be replaced by a single number for
%        selecting just only the SC_LEVELS deepest scales.
%
%        An all-ones vector, or a single number equal to SCALES, is the same
%        as the normal inverse transform.
%         
%        IWT (WX,RH,RG,SCALES,SIZ,SC_LEVELS,DEL1,DEL2) calculates the
%        inverse transform or performs the multiresolution analysis, but
%        allowing the users to change the alignment of the outputs with
%        respect to the input signal. This effect is achieved by setting to
%        DEL1 and DEL2 the analysis delays of H and G respectively, and
%        calculating the complementary delays for synthesis filters RH and
%        RG. The default values of DEL1 and DEL2 are calculated using the
%        function WTCENTER.
% 
% This function is a wrapper for iwtnd, for compatibility with UviWave.  See
% below for UviWave copyright.
%
% See also:  WTND, WT, IWT, WTCENTER, ISPLIT.
%
% $Id: iwt.m,v 1.5 2004/07/16 03:50:03 matthewbrett Exp $

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
%       Author: Sergio J. Garcia Galan 
%       e-mail: Uvi_Wave@tsc.uvigo.es
%--------------------------------------------------------

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
p_dims = zeros(1, n_dims);
if sz(2) > 1
  p_dims(2) = 1;
else 
  p_dims(1) = 1; 
end
  
if n_dims > 2
  warning('iwt does a 1D transform; use iwtnd for N-D transforms');
end
y = iwtnd(wx, rh, rg, scales, tam, sc_levels, del1, del2, p_dims);