function w = uisetparams(w,defval)
% uisetparams - sets params for parameterized wavelet
%
% $Id: uisetparams.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 2
  defval = [];
end
if isa(defval, 'phiw_wavelet')
  defval = defval.params;
end

w.params = spm_input('Parameter for wavelet','+1','e',defval,1);