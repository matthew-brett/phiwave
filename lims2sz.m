function sz = lims2sz(lims)
% szs = lims2szs(lims), returns data size for limits
% limits given in lims matrix (2 by no of dimensions)
%
% $Id: lims2sz.m,v 1.1.1.1 2004/06/25 15:20:35 matthewbrett Exp $
  
if nargin < 1
  error('Need lims');
end
if isempty(lims)
  sz = 0;
  return
end

sz = 1;
[t n] = size(lims);
for d = 1:n
  sz = sz * (lims(2,d)-lims(1,d)+1);
end