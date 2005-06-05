function w = pr_seat_thresh(X)
% Thresholding by Signal Estimation Algorithm
% FORMAT w = pr_seat_thresh(X)
%
% Inputs
% X        - vector of wavelet coefficients (variance is supposed 1);
% 
% Outputs
% w        - threshold
%             
%  Reference
%    Polchlopek HM, Noonan JP (1997) "Wavelets, Detection, Estimation
%    and Sparsity", Digital Signal Processing, 7:28-36
%
%	Federico E. Turkheimer
%	August 13th, 1998
%
% $Id: pr_seat_thresh.m,v 1.1 2005/06/05 04:17:42 matthewbrett Exp $
        
  X    = abs(X);
  n    = length(X);
  chi  = sum(X.^2);
  sig  = chi-n;
  
  if(sig < 0),
    w=inf;
  else
    for k=n:-1:1,
      s = sum(X(k:n).^2);
      if (s>sig),
	w=X(k);
	break
      end
    end
  end
  
  