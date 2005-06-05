function procf = isproc(obj)
% returns 1 if wvimg data is ready for access, 0 otherwise
%
% $Id: isproc.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $
  
procf = ~isstruct(obj.img) & obj.wtf;