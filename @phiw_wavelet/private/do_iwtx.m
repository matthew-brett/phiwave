function t = do_iwtx(t, rh, rg, dlp, dhp, reco_detail) 
% do first scale inverse wavelet transform in x dimension of matrix   
% FORMAT t = do_iwtx(t, rh, rg, dlp, dhp, reco_detail) 
%  
% Calculates the first-scale 1D inverse wavelet transform along the X
% dimension of matrix t, which should be a wavelet transformed matrix. The
% second argument rh is the synthesis lowpass filter and the third argument
% rh is the synthesis highpass filter.
%  
% dlp, dhp are the delays for the low-pass and high-pass filters.
% reco_detail is a flag; if zero, detail is not reconstructed into signal
%
% $Id: do_iwtx.m,v 1.1 2004/07/08 04:26:28 matthewbrett Exp $

%-This is the help file for the compiled routine
error('do_iwtx.c not compiled - see make.m in phiwave directory')
