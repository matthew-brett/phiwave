function wave = putwave(vol,wave)
% putwave - associates wave object with mat file
%
% $Id: putwave.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 2
  error('Need vol and wave as args');
end
if isstruct(vol),vol = vol.fname;end
if ~ischar(vol), return, end
if ~isa(wave,'phiw_wvimg')
  error('Need phiw_wvimg as input');
end
matfilerw(vol,'wave',wave);