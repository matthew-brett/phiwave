function [obj, wvol] = write_wtimg(obj, fname)
% saves wvimg object as .img / .mat combination
% 
% Input
% obj         - wvimg object
% fname       - output filename
% 
% Output
% obj         - returned object
% wvol        - output vol struct
%
% $Id: write_wtimg.m,v 1.3 2005/06/05 04:42:22 matthewbrett Exp $

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