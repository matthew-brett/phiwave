function odim = outdim(w, idim)
% outdim - returns output dimensions for wavelet transformed vol
% of input dimensions idim
% This template function assumes dyadic dimensions are 
% required and that first two output dimensions must be the same
%
% $Id: outdim.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 2
  error('Need input dimensions');
end
idim2 = idim(:)';
if ndims2(idim2) > 1
  idim2(1:2) = max(idim2(1:2));
end
odim = 2.^(ceil(log2(idim2)));