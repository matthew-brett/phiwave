function thresh = pr_sure_thresh(x)
% Adaptive Threshold Selection Using Principle of SURE
% FORMAT thresh = pr_sure_thresh(x)
%
% Inputs 
% y        - Noisy Data with Std. Deviation = 1
% 
% Outputs 
% thresh   - Value of Threshold
%
% Description
% SURE refers to Stein's Unbiased Risk Estimate.
%
% Federico Turkheimer
%
% $Id: pr_sure_thresh.m,v 1.1 2005/06/05 04:17:42 matthewbrett Exp $

  a = sort(abs(x)).^2 ;
  b = cumsum(a);
  n = length(x);
  c = linspace(n-1,0,n);
  s = b+c.*a;
  risk = (n - ( 2 .* (1:n ))  + s)/n;
  [guess,ibest] = min(risk);
  thresh = sqrt(a(ibest));
  