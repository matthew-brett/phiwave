function wvimg = doproc(wvimg)
% doproc - performs any necessary processing
%
% $Id: doproc.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

% read the data if it's a vol struct
if isstruct(wvimg.img)
  if wvimg.options.verbose
    fprintf('Reading image %s...\n', wvimg.img.fname);
  end
  wvimg.img = spm_read_vols(wvimg.img);
end  

% transform if not transformed
if ~wvimg.wtf
  wvimg.changef = 1;
  if wvimg.options.verbose
    fprintf('Transforming data for %s...\n', wvfname(wvimg));
  end
  % set NaN to 0
  wvimg.img(isnan(wvimg.img)) = 0;
  [wvimg.img wvimg.oimgi] = transform(wvimg.img,wvimg.wavelet, ...
				      wvimg.scales);
  wvimg.wtf = 1;
  wvimg.descrip = strvcat(wvimg.descrip,['wt with ' ...
		    descrip(wvimg.wavelet)]);
end