function w = phiw_lemarie(params, inp)
% phiw_lemarie - class constructor
% inherits from phiw_wavelet
%
% $Id: phiw_lemarie.m,v 1.2 2004/06/28 15:49:46 matthewbrett Exp $

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

% check params argument
if isempty(params)
  params = 2;
end
if ~isnumeric(params)
  error('Params should be numeric');
end

a.lemarie = [];
w = class(a, myname, phiw_wavelet(params, inp));