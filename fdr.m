function H = fdr(p,alfa,No,sortf)
% FDR - False Discovery Rate: adaptive algorithm.
% FORMAT H = FDR(p,alfa,No,sortf)
% 
% Input:
% p		= pvalues
% alfa		= FDR
% No		= number of Null Hypotheses
% sortf         = is 1 if p is already sorted ascending
% 
% Output:
% H		= vector of rejections 
%                 1 hypothesis rejected
%                 0 otherwise
%
% References:
% 
% Benjamini Y, Hochberg Y (2000)"On the adaptive control of the false
% discovery rate in multiple testing with independent statistics" Journal of
% Educational and Behavioral Statistics, 25:(1),60-83 (2000).
% 
% Benjamini Y, Hochberg Y (1995). ``Controlling the False Discovery Rate:
% a Practical and Powerful Approach to Multiple Testing',Journal
% of the Royal Statistical Society B, 57 289-300.
%
%
% Federico E. Turkheimer 16/2/2001, Matthew Brett 1/6/2001
%
% $Id: fdr.m,v 1.2 2004/09/14 05:30:29 matthewbrett Exp $

if nargin < 1
  error('Need p values');
end
if nargin < 2
  alfa = 0.05;
end
n	= length(p);
if nargin < 3
  No = n;
elseif No > n
  No = n;
end
if nargin < 4
  sortf = 0;
end
if ~sortf
  q = sort(p(:));
else
  q = p(:);
end

H = zeros(size(p));

idx = 1:n;
brk = max(find(q<=idx'*alfa/No));
if isempty(brk), return, end
idx = 1:(brk-1);
if any(q(idx)<=idx'*alfa/n)
  th = q(brk);
  H(p<=th) = 1;
end

return