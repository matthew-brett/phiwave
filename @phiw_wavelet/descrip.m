function str = descrip(w)
% descrip - returns string describing wavelet
%
% $Id: descrip.m,v 1.2 2004/11/18 18:58:54 matthewbrett Exp $

str = class(w);

% Basic wavelet
if strcmp(class(w), 'phiw_wavelet')
  [H G] = get_filters(w);
  Hs = sprintf(' %0.2f', H);
  Gs = sprintf(' %0.2f', G);
  str = [str ' - analysis:' Hs ', synthesis:' Gs];
else 
  str = [str ' - parameterized wavelet'];
end