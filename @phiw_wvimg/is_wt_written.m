function procf = is_wt_written(obj)
% returns 1 if wvimg data has been written as vol to disk
%
% $Id: is_wt_written.m,v 1.1 2005/04/06 22:31:41 matthewbrett Exp $
  
procf = ~isstruct(obj.img) & obj.wtf;