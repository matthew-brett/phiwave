function wv = get_wave(D)
% returns wavelet image object from design
% 
% $Id: get_wave.m,v 1.1 2005/04/20 15:07:52 matthewbrett Exp $

if ~has_images(D), wv = []; return; end
VY = get_images(D);

% get wave transform parameters
options = struct('noproc',1);
wv = phiw_wvimg(VY(1), options);
