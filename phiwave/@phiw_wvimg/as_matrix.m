function r = as_matrix(obj, m)
% returns wvimg object as wt image matrix, or sets matrix in object
% 
% $Id: as_matrix.m,v 1.2 2005/05/31 23:58:54 matthewbrett Exp $

if nargin < 2  % get
  obj = doproc(obj);
  r = obj.img;
else
  obj.img = m;
  r = obj;
end