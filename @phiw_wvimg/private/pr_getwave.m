function wave = pr_getwave(vol)
% getwave - returns wave object for vol, if available (empty if not)
%
% $Id: pr_getwave.m,v 1.1 2005/04/03 05:18:25 matthewbrett Exp $

if nargin < 1
  error('Need vol as arg');
end
wave = [];
if ~isstruct(vol), return, end
tmp = matfilerw(vol);
if isfield(tmp{1}, 'wave')
  wave = tmp{1}.wave;
end