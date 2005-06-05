function [blks, subs, sz] = pr_procsubs(wvlt,imsz,scales,subs)
% returns elements and processed subs arg for indexing
% FORMAT [blks, subs, sz] = pr_procsubs(wvlt,imsz,scales,subs)
%
% $Id: pr_procsubs.m,v 1.1 2005/06/05 04:17:42 matthewbrett Exp $

if nargin < 4
  error('Need four args')
end

% levels, quadrants
[tmp qs nquads] = levels(wvlt,imsz,scales);

% deal with ':', logical and indices addressing
fullinds = {1:scales+1, 1:nquads-1};
if length(subs) < 2
  subs{2} = ':';
end
for i = 1:2
  if subs{i} == ':'
    subs{i} = fullinds{i};
  end
  subs{i} = fullinds{i}(subs{i});
end

blks = [];
for l = subs{1}
  if l > scales
    if any(subs{2}==1)
      blks = [blks qs{l}];
    end
  else
    for q = subs{2}
      blks = [blks qs{l}(q)];
    end
  end
end

% get size
bno = length(blks);
sz = zeros(bno,1);
for b = 1:bno
  sz(b) = phiw_lims('size', blks{b});
end