function n = pr_ndims2(dims)
% returns no of dimensions, from size matrix, detecting vectors
%
% $Id: pr_ndims2.m,v 1.1 2005/06/01 09:29:59 matthewbrett Exp $

n = length(dims);
if n == 2 & any(dims == 1), n =1; end
