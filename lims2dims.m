function dims = lims2dims(lims)
% lims2dims, returns data dimensions for limits
% limits given in lims matrix (2 by no of dimensions)
%
% $Id: lims2dims.m,v 1.1 2004/06/25 15:20:35 matthewbrett Exp $
  
if nargin < 1
  error('Need lims');
end
if isempty(lims)
  dims = 0;
  return
end

dims = lims(2,:)-lims(1,:)+1;