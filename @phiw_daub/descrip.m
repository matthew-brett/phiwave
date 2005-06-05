function str = descrip(w)
% returns string describing Daubechies wavelet
%
% $Id: descrip.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

str = sprintf('%s - number of coefficients %d', class(w), w.num_coeffs);
