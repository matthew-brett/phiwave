function str = descrip(w)
% returns string describing wavelet
%
% $Id: descrip.m,v 1.4 2005/07/07 16:35:55 matthewbrett Exp $

str = class(w);

% Basic wavelet
if strcmp(class(w), 'phiw_wavelet')
  [H G] = get_filters(w);
  Hs = sprintf(' %0.2f', H);
  Gs = sprintf(' %0.2f', G);
  str = [str ' - analysis LP:' Hs ', analysis HP:' Gs];
else 
  str = [str ' - parameterized wavelet'];
end