function str = descrip(w)
% descrip - returns string describing wavelet
%
% $Id: descrip.m,v 1.1 2004/11/18 18:40:01 matthewbrett Exp $

str = sprintf('%s - dim divisor %d', class(w), w.dim_div);
