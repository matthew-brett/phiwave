function s = lims2subs(lims, type)
% s = lims2subs(lims, type), returns subs struct
% for limits given in lims matrix (2 by no of dimensions)
% useful in indexing in subsasgn, subsref
%
% $Id: lims2subs.m,v 1.1.1.1 2004/06/25 15:20:35 matthewbrett Exp $
  
if nargin < 1
  error('Need lims');
end
if nargin < 2
  type = '()';
end

[t n] = size(lims);
s = struct('type',type);
for d = 1:n
  s.subs{d} = lims(1,d):lims(2,d);
end