function procf = isproc(obj)
% isproc - returns 1 if wvimg data is ready for access, 0 otherwise
%
% $Id: isproc.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
procf = ~isstruct(obj.img) & obj.wtf;