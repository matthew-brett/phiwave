% Make compiled files for PhiWave
% 
% You may want to look into the optimizations for mex compilation
% See the SPM99 spm_MAKE.sh file or SPM2 Makefile for examples
% 
% My favorite compilation flags for a pentium 4 system, linux, gcc are:
% -fomit-frame-pointer -O3 -march=pentium4 -mfpmath=sse -funroll-loops
%
% $Id: make.m,v 1.2 2004/07/08 05:23:34 matthewbrett Exp $

mex @phiw_wvimg/private/pplot_elbow.c
mex @phiw_wavelet/private/do_wtx.c
mex @phiw_wavelet/private/do_iwtx.c