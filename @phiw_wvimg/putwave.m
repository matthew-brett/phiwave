function wave = putwave(vol,wave)
% putwave - associates wave object with mat file
%
% $Id: putwave.m,v 1.2 2005/06/01 09:26:53 matthewbrett Exp $

if nargin < 2
  error('Need vol and wave as args');
end
if isstruct(vol),vol = vol.fname;end
if ~ischar(vol), return, end
if ~isa(wave,'phiw_wvimg')
  error('Need phiw_wvimg as input');
end
pr_matfilerw(vol,'wave',wave);