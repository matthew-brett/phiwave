function thresh = ValSUREThresh(x)
% Adaptive Threshold Selection Using Principle of SURE
% Usage 
%    thresh = ValSUREThresh(y)
% Inputs 
%    y        Noisy Data with Std. Deviation = 1
% Outputs 
%    thresh   Value of Threshold
%
% Description
%    SURE refers to Stein's Unbiased Risk Estimate.
%
% Federico Turkheimer
%
% $Id: ValSUREThresh.m,v 1.1.1.1 2004/06/25 15:20:44 matthewbrett Exp $

  a = sort(abs(x)).^2 ;
  b = cumsum(a);
  n = length(x);
  c = linspace(n-1,0,n);
  s = b+c.*a;
  risk = (n - ( 2 .* (1:n ))  + s)/n;
  [guess,ibest] = min(risk);
  thresh = sqrt(a(ibest));
  