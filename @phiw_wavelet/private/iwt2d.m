function y=iwt2d(wx,rh,rg,scales,sizx,sizy,sc_levels,del1,del2)
% IWT2D Two dimensional Inverse Wavelet Transform.
%
%       IWT2D(WX,RH,RG,SCALES) calculates the two dimensional inverse
%       wavelet transform of matrix WX, which is supposed to be a two
%       dimensional SCALES-scales direct wavelet transform of any matrix or
%       image. RH is the synthesis lowpass filter and RG is the synthesis
%       highpass filter.
%
%       The original image size can be provided by specifying IWT2D
%       (WX,RH,RG,SCALES,SIZX,SIZY). If any of SIZX or SIZY is not given or
%       set to zero, IWT2D will calculate the maximum for the direction.
%
%       IWT2D can be used to perform a single process of multiresolution
%       analysis. The way to do it is by selecting the scales whose highpass
%       bands (detail signals) should be ignored for reconstruction.
%
%       Using IWT2D (WX,RH,RG,SCALES,SIZX,SIZY,SC_LEVELS) where SC_LEVELS is
%       a SCALES-sized vector, 1's or 0's. An i-th coefficient of 0 means that
%       the i-th scale detail images (starting from the deepest) should be
%       ignored.  The SC_LEVELS vector can be replaced by a single number
%       for selecting just only the SC_LEVELS deepest scales.
%
%       An all-ones vector, or a single number equal to SCALES, is the same 
%       as the normal inverse transform. 
%         
%       IWT2D (WX,RH,RG,SCALES,SIZX,SIZY,SC_LEVELS,DEL1,DEL2) calculates the
%       inverse transform or performs the multiresolution analysis, but
%       allowing the users to change the alignment of the outputs with
%       respect to the input signal. This effect is achieved by setting to
%       DEL1 and DEL2 the analysis delays of H and G respectively, and
%       calculating the complementary delays for synthesis filters RH and
%       RG. The default values of DEL1 and DEL2 are calculated using the
%       function WTCENTER.
% 
% This function is a wrapper for iwtnd, for compatibility with UviWave.  See
% below for UviWave copyright.
%
% See also:  WTND, IWT, IWTND, WTCENTER, ISPLIT.
%
% $Id: iwt2d.m,v 1.3 2004/07/16 03:53:34 matthewbrett Exp $

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
  sizx = [];
end
if nargin < 6
  sizy = [];
end
if nargin < 7
  sc_levels = [];
end
if nargin < 8
  del1 = [];
end
if nargin < 9
  del2 = [];
end

n_dims = ndims(wx);
p_dims = [1 1 zeros(1, n_dims-2)];
  
if n_dims > 2
  warning('iwt2d does a 2D transform; use iwtnd for N-D transforms');
end

% Note that UviWave iwt2d takes the first passed size as the width
% (number of columns) and the second passed size as the height (number of
% rows) whereas wtnd follows the matlab convention of number of rows
% first, then number of columns
y = iwtnd(wx, rh, rg, scales, [sizy sizx], sc_levels, del1, del2, p_dims);
