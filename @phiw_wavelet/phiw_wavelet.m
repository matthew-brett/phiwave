function w = phiw_wavelet(params, flag)
% phiw_wavelet - class constructor
% inputs [defaults]
%  params  - maybe a filter structure containing fields
%             H  - analysis low pass  [1]
%             G  - analysis high pass [1]
%             RH - synthesis low pass [1]
%             RG - synthesis high pass[1]
%
%  flag     - specifies detail coeffs to right (UviWave) [1]
%
% $Id: phiw_wavelet.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
if nargin < 1
  params = [];
end
if nargin < 2
  % flag to specify detail coeffs go to right
  % as for UviWave
  flag = 1;  
end
if isempty(params)
  % inp1 is wavelet filter structure
  params = struct('H',1,'G',1,'RH',1,'RG',1);
end
if isa(params, 'phiw_wavelet')
  w = params;
else
  s.rightf = flag;
  s.params = params;
  w = class(s, 'phiw_wavelet');
end