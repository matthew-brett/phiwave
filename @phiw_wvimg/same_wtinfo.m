function tf = same_wtinfo(wvobj, wtinfo)
% returns 1 if wtinfo structure matches wvobj
% FORMAT tf = same_wtinfo(wvobj, wtinfo)
% 
% Input 
% wvobj     - phiw_wvimg object
% wtinfo    - wtinfo structure with fields
%               scales
%               wavelet
% 
% The function only compares fields passed, so wtinfo can contain only
% 'scales', or only 'wavelet', for example.  
% Function returns 0 if wtinfo is empty
%
% $Id: same_wtinfo.m,v 1.1 2004/11/18 18:43:11 matthewbrett Exp $

tf = 0;
if nargin < 2
  error('Need wtinfo to compare');
end

wv_struct = mars_struct('split', struct(wvobj), wtinfo);
if isempty(wv_struct), return, end
fns = fieldnames(wv_struct);
for fn = 1:length(fns)
  f = fns{fn};
  if getfield(wv_struct, f) ~= getfield(wtinfo, f), return, end
end
tf = 1;