function odim = outdim(w, idim)
% returns output dimensions for wavelet transformed vol, input dimensions idim
% FORMAT odim = outdim(w, idim)
% 
% This template function assumes dyadic dimensions are 
% required and that first two output dimensions must be the same
%
% $Id: outdim.m,v 1.3 2005/06/05 04:42:22 matthewbrett Exp $

if nargin < 2
  error('Need input dimensions');
end
idim2 = idim(:)';
if pr_ndims2(idim2) > 1
  idim2(1:2) = max(idim2(1:2));
end
odim = 2.^(ceil(log2(idim2)));