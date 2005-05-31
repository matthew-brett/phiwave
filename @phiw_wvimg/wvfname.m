function fname = wvfname(obj)
% wvfname - return wvol output filename
%
% $Id: wvfname.m,v 1.4 2005/05/31 00:48:30 matthewbrett Exp $

if prod(size(obj)) > 1, fname = 'object array'; return, end

% try wvol fname first
fname = mars_struct('getifthere', obj.wvol, 'fname');
if isempty(fname)
  % then try ovol fname 
  fname = mars_struct('getifthere', obj.ovol, 'fname');
  if isempty(fname), fname = 'image.img'; end
  [p f e] = fileparts(fname);
  wtp = mars_struct('getifthere', obj.options, 'wtprefix');
  fname = fullfile(p,[wtp f e]);
end