function wti = wtinfo(obj)
% method returns WT info structure from object
% 
% $Id: wtinfo.m,v 1.1 2004/11/18 18:43:59 matthewbrett Exp $

wti = struct('scales', obj.scales, ...
	     'wavelet', obj.wavelet, ...
	     'wtprefix', obj.options.wtprefix);