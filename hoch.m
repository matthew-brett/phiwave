function H = hoch(p,alfa,No,sortf)
%	HOCH - Step up correction for multiple comparisons.
%
%	References:
%	Hochberg Y (1988) "A sharper Bonferroni procedure for 
%		multiple tests of significance," Biometrika 75:800-803 
%	Hochberg Y, Benjamini Y (1990) "More powerful procedures for 
%		multiple significance testing," Statist.  Med. 9:811-818
%
%	Usage:	H = hoch(p,alfa,No,sortf)
%	Input:
%		p		= pvalues
%		alfa		= FWE
%		No		= number of Null Hypotheses
%               sortf           = is 1 if p is already sorted ascending
%	Output:
%		H		= vector of rejections 
%				1	hypothesis rejected
%				0 	otherwise
%
% 	Federico E. Turkheimer 15/6/2000, Matthew Brett 1/6/2001
%
% $Id: hoch.m,v 1.1 2004/06/25 15:20:35 matthewbrett Exp $

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

H1 = q < alfa./(min(No, (n:-1:1)'+1));
th = max([q(H1); 0]);
H = p<= th;

return