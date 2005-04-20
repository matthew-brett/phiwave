function [iwtvol, obj] = write_iwtimg(obj, iwtvol)
% write_wtimg - iwt on wvimg object, save as img
%
% $Id: write_iwtimg.m,v 1.4 2005/04/20 15:19:22 matthewbrett Exp $

if nargin < 2
  iwtvol = [];
end
if isempty(iwtvol)
  error('Need output filename or vol struct');
end
if ischar(iwtvol)
  iwtvol = struct('fname',iwtvol); 
end

if ~obj.wtf
  error('Object is not wt''ed');
else
  obj = doproc(obj);
end

% fill missing fields in vol struct first from origincal vol struct
iwtvol = mars_struct('fillafromb', iwtvol, obj.ovol);

% then get any missing defaults from wvol
iwtvol = mars_struct('fillafromb', iwtvol,obj.wvol);

% do iwt
if obj.options.verbose
  fprintf('Inverting transform on %s...\n', obj.wvol.fname);
end

% set NaN's to zero...
img = obj.img;
img(isnan(img)) = 0;

% Do inverse transform
img = invert(img, obj.wavelet, obj.scales, obj.oimgi);

% set up iwtvol
iwtvol.dim(1:3) = size(img);
iwtvol.descrip = obj.descrip;

% save (might have to do something about complex images here)
iwtvol = spm_write_vol(iwtvol, img);