function tf = same_wtinfo(wvobj, test_wtinfo)
% returns 1 if wtinfo structure matches wvobj
% FORMAT tf = same_wtinfo(wvobj, test_wtinfo)
% 
% Input 
% wvobj          - phiw_wvimg object
% test_wtinfo    - wtinfo structure with none or more fields
%                   scales
%                   wavelet
%                   wtprefix
%
% The function only compares fields passed, so test_wtinfo can contain only
% 'scales', or only 'wavelet', for example.  
%
% Function returns 0 if test_wtinfo is empty
%
% $Id: same_wtinfo.m,v 1.2 2005/04/03 06:57:27 matthewbrett Exp $

tf = 0;
if nargin < 2
  error('Need wtinfo to compare');
end
if isempty(test_wtinfo), return, end

o_wtinfo = wtinfo(wvobj);
fns = fieldnames(test_wtinfo);
for fn = 1:length(fns)
  f = fns{fn};
  if getfield(o_wtinfo, f) ~= getfield(test_wtinfo, f), return, end
end
tf = 1;