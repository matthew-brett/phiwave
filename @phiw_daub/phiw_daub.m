function w = phiw_daub(params, inp)
% phiw_daub - class constructor
% inherits from phiw_wavelet
%
% $Id: phiw_daub.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

myname = 'phiw_daub';  
if nargin < 1
  params = [];
end
if nargin < 2
  inp = 1; % right is detail (UviWave)
end
if isa(params, myname)
  w = params;
  return
end
a.daub = '';
w = class(a, myname, phiw_wavelet(params,inp));