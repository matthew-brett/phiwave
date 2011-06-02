function wave = pr_getwave(vol)
% returns wave object for vol, if available (empty if not)
%
% $Id: pr_getwave.m,v 1.3 2005/06/05 04:42:22 matthewbrett Exp $

if nargin < 1
  error('Need vol as arg');
end
wave = [];
if ~isstruct(vol), return, end
tmp = pr_matfilerw(vol);
if isfield(tmp{1}, 'wave')
  wave = tmp{1}.wave;
end