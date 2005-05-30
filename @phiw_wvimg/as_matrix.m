function m = as_matrix(obj)
% returns wvimg object as wt image matrix
% 
% $Id: as_matrix.m,v 1.1 2005/05/30 16:41:43 matthewbrett Exp $
  
obj = doproc(obj);
m = obj.img;