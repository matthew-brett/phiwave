function t = do_wtx_m(t, h, g, dlp, dhp)
% do first scale wavelet transform in x dimension of matrix
% FORMAT t = do_wtx(t, h, g, L, dlp, dhp)
% 
% $Id: do_wtx_m.m,v 1.2 2004/07/09 23:40:22 matthewbrett Exp $ 
  
lx=size(t, 1);
n_dims = ndims(t);

% Function does not deal with odd row lengths elegantly
if (lx/2 ~= floor(lx/2)), error('Size in x should be multiple of 2'); end

% The number of samples for the wrapparound. Thus, we should need to move
% along any L samples to get the output wavelet vector phase equal to
% original input phase.  Note delays can be negative
lh = length(h); lg = length(g);
L=max([lh lg dlp dhp lh-dlp lg-dhp]);	
	    
% Build wrapparound. The input signal can be smaller than L, so it
% can be necessary to repeat it several times
wrap_repeats = ceil(L/lx);
wrap_indices = repmat(1:lx, 1, wrap_repeats);
wrap_b = wrap_indices(end-L+1:end);
wrap_e = wrap_indices(1:L);

% Add wraparound
switch n_dims
 case 2
  t=[t(wrap_b, :); t; t(wrap_e, :)];
 case 3
  t=[t(wrap_b, :, :); t; t(wrap_e, :, :)];
 case 4
  t=[t(wrap_b, :, :, :); t; t(wrap_e, :, :, :)];
 otherwise
  error('Not implemented');
end
      
% Make into vector - it's slightly faster even for long L
% maybe due to cache blocking
sz = size(t);
t = t(:);

% Then do lowpass, highpass filtering ...
yl=filter(h, 1, t);	       	
yh=filter(g, 1, t); 
      
% Reshape to matrix
yl = reshape(yl, sz);
yh = reshape(yh, sz);

% Decimate the outputs, leaving out wraparound
dec_indices_lp = (dlp+1+L):2:(dlp+L+lx);
dec_indices_hp = (dhp+1+L):2:(dhp+L+lx);
switch n_dims
 case 2 
  yl=yl(dec_indices_lp, :);    
  yh=yh(dec_indices_hp, :);    
 case 3 
  yl=yl(dec_indices_lp, :, :);    
  yh=yh(dec_indices_hp, :, :);    
 case 4 
  yl=yl(dec_indices_lp, :, :, :);    
  yh=yh(dec_indices_hp, :, :, :);    
 otherwise
  error('Not implemented');
end

% Put the resulting wavelet step on its place into the wavelet
% vector; generates UviWave ordering
t =[yl; yh];
