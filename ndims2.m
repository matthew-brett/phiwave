function n = ndims2(dims)
% returns no of dimensions, from size matrix, detecting vectors
%
% $Id: ndims2.m,v 1.1 2004/06/25 15:20:36 matthewbrett Exp $

n = length(dims);
if n == 2 & any(dims == 1), n =1 ;end