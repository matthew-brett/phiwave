function str = descrip(w)
% returns string describing wavelet
%
% $Id: descrip.m,v 1.3 2005/06/05 04:42:22 matthewbrett Exp $

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