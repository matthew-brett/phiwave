function thinobj = thin(obj, nosavef)
% thin - returns object without image included
% FORMAT thinobj = thin(obj, nosavef)
% where nosavef prevents object image save even if there
% have been changes to the object since creation
%
% $Id: thin.m,v 1.2 2005/04/03 07:24:32 matthewbrett Exp $
  
if nargin < 2
  nosavef = 0;
end
if obj.changef & ~nosavef
  thinobj = write_wtimg(obj);
else
  thinobj = obj;
end
thinobj.img = thinobj.wvol;
