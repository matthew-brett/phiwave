function fname = wvfname(obj)
% wvfname - return wvol output filename
%
% $Id: wvfname.m,v 1.2 2004/11/18 19:05:46 matthewbrett Exp $

if prod(size(obj)) > 1, fname = 'object array'; return, end

% try wvol fname first
if ~isempty(obj.wvol.fname),fname = obj.wvol.fname;
else
  % then try ovol fname 
  fname = 'image.img';
  if ~isempty(obj.ovol.fname),fname = obj.ovol.fname;end
  [p f e] = fileparts(fname);
  fname = fullfile(p,[obj.options.wtprefix f e]);
end