function str = descrip(w)
% descrip - returns string describing wavelet
%
% $Id: descrip.m,v 1.1 2004/11/18 18:39:12 matthewbrett Exp $

str = sprintf('%s - number of coefficients %d', class(w), w.num_coeffs);
