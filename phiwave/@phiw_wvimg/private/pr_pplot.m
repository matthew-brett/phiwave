function [nullh,nullhint]=pr_pplot(p,alpha,sortf)
% Sparsity estimation with pplot
% FORMAT [nullh,nullhint]=pr_pplot(p,alpha,sortf)
%
% Input:
% p        - pvalues (column vector)
% alpha    - probability for confidence intervals
% sortf    - non-zero if p values are sorted ascending
% 
% Output:
% nullh	   - estimated number of null coefficients
%            The solution is constrained to between 0 and length(p).
% nullhint - 100(1-alpha) confidence intervals. These incorporate the
%             uncertainty due to the Least Squares procedure, not that due
%             to the selection procedure.
%
% 	Federico E. Turkheimer, June 15th, 2000
%
% $Id: pr_pplot.m,v 1.1 2005/06/05 04:17:42 matthewbrett Exp $

if nargin < 1
  error('Need p values');
end
if nargin < 2
  alfa = 0.05;
end

[h,k]	= size(p);		% resizing to column
if(k>1)p=p';end;
n	= length(p);

if nargin < 3
  sortf = 0;
end
if ~sortf
  q = sort(p);
else
  q = p;
end

q	= flipud(1-q);

%	Point-Change analysis
%	Reference:
%	Stephens MA, "Tests for the Uniform Distribution", 
%	In Goodness-of-Fit Techniques (D'Agostino RB, Stephens MA Eds.)
%	NewYork, Marcel Dekker, pp.331-366, 1986
i       = pplot_elbow(q);

% 	Weights = inverse of the variance of a Beta variable
%	Reference:
%	Quesenberry CP and Hales C, "Concentration Bands for Uniformity 
%	Plots", J. Statist. Simul. Comput., 1980, 11:41-53.

j	= (1:i)';
v	= (j.*(i-j+1))/((i+2)*(i+1)^2);	
w	= 1./v(1:i);

%	Weighted Linear Regression			
x	= (1:i)';
y	= q(1:i);
sxx	= sum(w.*(x.^2));
c	= sum(w.*x.*y)/sxx;

nu 		= length(x)-1;              		% Regression degrees of freedom
yhat 		= c*x;					% Predicted responses at each data point.
r 		= y-yhat;  	                	% Residuals.             
rmse 		= sqrt(sum((r.^2).*w)/(nu*sxx));	% error
tval 		= spm_invTcdf((1-alpha/2),nu);


nullh		= ceil(1/c)-1;
temp		= 1/c;
diff		= nullh-temp;
if (c<0),
   nullh 	= 0;
   nullhint	= 0;
end

if (nullh>length(p)),
   nullh 	= length(p);
   nullhint	= 0;
end

cint 		= [c-tval*rmse, c+tval*rmse];
nullhint	= [1./cint-1 + diff];			% Correction for rounding