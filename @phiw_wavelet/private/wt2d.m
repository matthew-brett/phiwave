function y=wt2d(x,h,g,scales,del1,del2)
% WT2D   Two dimensional Wavelet Transform. 
%
%       WT2D(X,H,G,SCALES) calculates the 2D wavelet transform of matrix X
%       at SCALES scales. H is the analysis lowpass filter and G is the
%       highpass one.
%
%       At every scale, the lowpass residue is placed at the top-left corner
%       of the corresponding subimage, the horizontal high frequency band at
%       the top-right, the vertical high frequency band at the bottom-left
%       and the diagonal high frequency band at the bottom-right. Every
%       successive wavelet subimage substitutes the residue of the previous
%       scale.
%	
%		Example with 2 scales:
%					 _______
%	2nd scale substituting the  -->	|_|_|   | <-- 1st scale 
%	first scale lowpass residue	|_|_|___|     horiz. detail	
%					|   |   | 
%		        1st scale ---->	|___|___| <-- 1st scale 
%		      vertical detail		    diagonal detail
%
%       WT2D (X,H,G,SCALES,DEL1,DEL2) will perform the transformation but
%       allowing the user to change the alignment of the output subimages
%       with respect to the input image. This effect is achieved by setting
%       to DEL1 and DEL2 the delays of H and G respectively. The default
%       values of DEL1 and DEL2 are calculated using the function WTCENTER.
% 
% This function is a wrapper for wtnd, for compatibility with UviWave.  See
% below for UviWave copyright.
%
% See also:  WTND, IWT, IWTND, WTCENTER, ISPLIT.
%
% $Id: wt2d.m,v 1.4 2004/07/16 03:51:38 matthewbrett Exp $

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

n_dims = ndims(x);
p_dims = [1 1 zeros(1, n_dims-2)];
  
if n_dims > 2
  warning('wt2d does a 2D transform; use wtnd for N-D transforms');
end
y = wtnd(x, h, g, scales, del1, del2, p_dims);