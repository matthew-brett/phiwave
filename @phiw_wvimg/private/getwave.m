function wave = getwave(vol)
% getwave - returns wave object for vol, if available (empty if not)
%
% $Id: getwave.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 1
  error('Need vol as arg');
end
wave = [];
if ~isstruct(vol), return, end
tmp = matfilerw(vol);
if isfield(tmp{1}, 'wave')
  wave = tmp{1}.wave;
end