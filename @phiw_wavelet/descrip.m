function str = descrip(w)
% descrip - returns string describing wavelet
%
% $Id: descrip.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

str = class(w);

% Basic wavelet  
p = w.params;
if isstruct(p) % wavelet with filters saved 
  Hs = sprintf(' %0.2f',p.H);
  Gs = sprintf(' %0.2f',p.G);
  str = [str ' - analysis:' Hs ', synthesis:' Gs];
else % parameterized wavelet
  str = sprintf('%s - params=%0.2f',str, p);
end