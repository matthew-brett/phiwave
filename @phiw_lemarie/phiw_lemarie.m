function w = phiw_lemarie(params, inp)
% phiw_lemarie - class constructor
% inherits from phiw_wavelet
%
% $Id: phiw_lemarie.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

myname = 'phiw_lemarie';  
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
a.lemarie = [];
w = class(a, myname, phiw_wavelet(params, inp));