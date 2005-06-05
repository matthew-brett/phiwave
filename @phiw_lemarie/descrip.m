function str = descrip(w)
% returns string describing wavelet
%
% $Id: descrip.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

str = sprintf('%s - dim divisor %d', class(w), w.dim_div);
