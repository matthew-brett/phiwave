function w = do_iwtx_m(w, rh, rg, dlp, dhp, reco_detail)
% do first scale inverse wavelet transform in x dimension of matrix
% FORMAT t = do_iwtx(t, h, g, L, dlp, dhp, reco_detail)
% 
% $Id: do_iwtx_m.m,v 1.3 2004/07/10 05:02:04 matthewbrett Exp $ 

if nargin < 5
  error('Need matrix, filters and delays');
end
if nargin < 6
  reco_detail = 1;
end

lx=size(w, 1);
n_dims = ndims(w);

% The number of samples for the wrapparound. Thus, we should need to move
% along any L samples to get the output wavelet vector phase equal to
% original input phase.  Note delays can be negative
lh = length(rh); lg = length(rg);
L=max([lh lg dlp dhp lh-dlp lg-dhp]);	

% 1 - The lowpass vector... interpolate it ending with a '0' so that
% the wraparound doesn't put two samples toghether.  The input signal
% can be smaller than L, so it can be necessary to repeat the
% wraparound several times
wrap_repeats = ceil(L/lx);
wrap_indices = repmat(1:lx, 1, wrap_repeats);
wrap_b = wrap_indices(end-L+1:end);
wrap_e = wrap_indices(1:L);
      
lp_inds = 1:lx/2;
hp_inds = lx/2+1:lx;
dat_inds = 1:2:lx;
yl = zeros(size(w));
switch n_dims
 case 2
  yl(dat_inds, :) = w(lp_inds, :);
  yl=[yl(wrap_b, :); yl; yl(wrap_e, :)];
 case 3
  yl(dat_inds, :, :) = w(lp_inds, :, :);
  yl=[yl(wrap_b, :, :); yl; yl(wrap_e, :, :)];
 case 4
  yl(dat_inds, :, :, :) = w(lp_inds, :, :, :);
  yl=[yl(wrap_b, :, :, :); yl; yl(wrap_e, :, :, :)];
 otherwise
  error('Not implemented');
end

% Process the highpass band only if SCALES_LEVELS specifies to do so.
if reco_detail		
  
  yh = zeros(size(w));
  switch n_dims
   case 2
    yh(dat_inds, :) = w(hp_inds, :);
    yh=[yh(wrap_b, :); yh; yh(wrap_e, :)];
   case 3
    yh(dat_inds, :, :) = w(hp_inds, :, :);
    yh=[yh(wrap_b, :, :); yh; yh(wrap_e, :, :)];
   case 4
    yh(dat_inds, :, :, :) = w(hp_inds, :, :, :);
    yh=[yh(wrap_b, :, :, :); yh; yh(wrap_e, :, :, :)];
   otherwise
    error('Not implemented');
  end
end

% Do the lowpass systhesis filtering and leave out the filter delays and
% the wraparound.

% Make into vector - it's slightly faster even for long L
% maybe due to cache blocking
sz = size(yl);
yl = yl(:);

% Then do lowpass filtering ...
yl=filter(rh, 1, yl);	       	

% Reshape to matrix
yl = reshape(yl, sz);

% put back into outputs leaving out wraparound, filter delays
dec_indices = (dlp+1+L):1:(dlp+L+lx);
switch n_dims
 case 2 
  yl=yl(dec_indices, :);    
 case 3 
  yl=yl(dec_indices, :, :);    
 case 4 
  yl=yl(dec_indices, :, :, :);    
 otherwise
  error('Not implemented');
end

% If necessary, do the same with highpass.
if reco_detail
  yh = yh(:);
  yh=filter(rg, 1, yh);	       	
  yh = reshape(yh, sz);
  dec_indices = (dhp+1+L):1:(dhp+L+lx);
  switch n_dims
   case 2 
    yh=yh(dec_indices, :);    
   case 3 
    yh=yh(dec_indices, :, :);    
   case 4 
    yh=yh(dec_indices, :, :, :);    
   otherwise
    error('Not implemented');
  end 
  % Sum the two outputs if we've reconstructed high-pass
  w=yl+yh;		
else 
  % or get only the lowpass side.
  w=yl;			
end;

% I found this code in iwt, but can't understand how this extra
% zero can be added
% $$$     lx=size(w, 1);
% $$$     % If the added '0' was not needed
% $$$     if lx>lo(d, proc_scale)
% $$$       w=w(1:lx-1);	% pick it out now, not before.
% $$$       lx=lx-1;	% (this reduces the next length)
% $$$     end
