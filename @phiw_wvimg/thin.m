function thinobj = thin(obj, nosavef)
% thin - returns object without image included
% FORMAT thinobj = thin(obj, nosavef)
% where nosavef prevents object image save even if there
% have been changes to the object since creation
%
% $Id: thin.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
if nargin < 2
  nosavef = 0;
end
if obj.changef & ~nosavef
  thinobj = write_wtimg(obj);
else
  thinobj = obj;
  thinobj.img = thinobj.wvol;
end