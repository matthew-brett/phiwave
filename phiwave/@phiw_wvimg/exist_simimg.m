function exf = exist_simimg(obj, fname)
% returns 1 if similar wt image already exists
% Similar means - same filename, same wavelet, same scales, same .mat
% and same dimensions
%
% $Id: exist_simimg.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

if nargin < 2
  fname = [];
end
if isempty(fname),fname=wvfname(obj);end

exf = 0;  
if ~exist(obj.wvol.fname, 'file'), return,end

tmpobj = phiw_wvimg(obj.wvol.fname,struct('noproc',1));
if isempty(tmpobj), return,end

exf = obj.wavelet == tmpobj.wavelet & ...
      obj.scales == tmpobj.scales & ...
      all(obj.wvol.dim(1:3) == tmpobj.wvol.dim(1:3)) & ...
      all(obj.wvol.mat(:)==tmpobj.wvol.mat(:));

  