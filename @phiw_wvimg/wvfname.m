function fname = wvfname(obj)
% wvfname - return wvol output filename
%
% $Id: wvfname.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

% try wvol fname first
if ~isempty(obj.wvol.fname),fname = obj.wvol.fname;
else
  % then try ovol fname 
  fname = 'image.img';
  if ~isempty(obj.ovol.fname),fname = obj.ovol.fname;end
  [p f e] = fileparts(fname);
  fname = fullfile(p,[obj.options.wtprefix f e]);
end