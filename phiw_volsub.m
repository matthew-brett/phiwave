function [wtvols, wave]=phiw_volsub(imgvols, wtinfo)
% converts voxel vols to wavelet transformed vols
% FORMAT [wtvols  wave]=phiw_volsub(imgvols, wtinfo)
%
% Input
% imgvols      - voxel vols
% wtinfo       - structure with info for required wt [PHI.wt]
% 
% Returns
% wtvols       - wavelet transformed vols
% wave         - phiw_wvimg object with wt info for these vols
%
% $Id: phiw_volsub.m,v 1.3 2004/11/18 18:48:36 matthewbrett Exp $
  
if nargin < 1
  error('Need image volume structures');
end
if nargin < 2
  phiw = spm('getglobal','PHI');
  wtinfo = phiw.wt;
end
if ~all(ismember({'scales', 'wavelet', 'wtprefix'},fieldnames(wtinfo))) | ...
      isempty(wtinfo.scales) | isempty(wtinfo.wavelet) | ...
      isempty(wtinfo.wtprefix)
  error('Need wavelet, scale, prefix information in wtinfo structure')
end

wvp = wtinfo.wtprefix;

nimgs = prod(size(imgvols));
options = struct('noproc',1,'wtprefix',wvp);

for i = 1:nimgs

  % check whether these is a wv image of same scale and wavelet type
  % Do transform and save if not;
  wvobj = phiw_wvimg(imgvols(i).fname,options,wtinfo.wavelet,wtinfo.scales);
  if ~exist_simimg(wvobj)
    wvobj = doproc(wvobj);
    % store without image data attached
    wvobj = thin(write_wtimg(wvobj));
  end
  
  % Map and rescale
  wtvols(i) = spm_vol(wvobj.wvol.fname);
  ovol = spm_vol(imgvols(i).fname);
  pinfos = [wtvols(i).pinfo imgvols(i).pinfo ovol.pinfo];
  if size(pinfos,2)~= 3
    error('Whoops, plane by plane scaling');
  end
  if any(pinfos(2,:))
    error('Whoops, scaling offsets')
  end
  wtvols(i).pinfo(1) = wtvols(i).pinfo(1) ....
      .* imgvols(i).pinfo(1) ...
      ./ ovol.pinfo(1);
end

% and return
wtvols = reshape(wtvols, size(imgvols));
wave = phiw_wvimg(wtvols(1),struct('noproc',1));

return