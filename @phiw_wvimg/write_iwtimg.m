function [iwtvol, obj] = write_iwtimg(obj, iwtvol)
% write_wtimg - iwt on wvimg object, save as img
%
% $Id: write_iwtimg.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 2
  iwtvol = [];
end

if ~obj.wtf
  error('Object is not wt''ed');
else
  obj = doproc(obj);
end

if ischar(iwtvol),iwtvol = struct('fname',iwtvol);end

% fname from 1) input 2) ovol 3) wvol (+prefix) 4) default (+prefix)
iwtvol = fillafromb(iwtvol,obj.ovol);
if isempty(iwtvol.fname)
  if isempty(obj.wvol.fname),iwtvol.fname = 'image';
  else iwtvol.fname = obj.wvol.fname;end
  [p f e] = fileparts(iwtvol.fname);
  iwtvol.fname = fullfile(p, [obj.options.iwtprefix f e]);
end
% any missing defaults from wvol
iwtvol = fillafromb(iwtvol,obj.wvol);

% do iwt
if obj.options.verbose
  fprintf('Inverting transform on %s...\n', obj.wvol.fname);
end
img = invert(obj.img, obj.wavelet, obj.scales, obj.oimgi);

% set up iwtvol
iwtvol.dim(1:3) = size(img);
iwtvol.descrip = obj.descrip;

% save (might have to do something about complex images here)
iwtvol = spm_write_vol(iwtvol, img);