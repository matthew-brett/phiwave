function [obj, wvol] = write_wtimg(obj, fname)
% write_wtimg - saves wvimg object as .img / .mat combination
%
% $Id: write_wtimg.m,v 1.2 2004/06/25 16:18:22 matthewbrett Exp $

if nargin < 2
  fname = [];
end

if isstruct(fname),fname = fname.fname;end
if isempty(fname), fname = wvfname(obj);end

% set up wvvol
obj = doproc(obj);
dim = size(obj.img);
dim(4) = spm_type(obj.options.datatype);
obj.wvol.dim = dim;
obj.wvol.fname = fname;
obj.wvol = mars_struct('fillafromb', obj.wvol,obj.ovol);
obj.wvol.descrip = obj.descrip;

% save (might have to do something about complex images here)
obj.wvol = spm_write_vol(obj.wvol, obj.img);

% set changef
obj.changef = 0;

% dump matrix data and write object information
putwave(obj.wvol, thin(obj));

wvol = obj.wvol;