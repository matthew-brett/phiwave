function [objs] = thresh_apply(objs, th_type, th_bin, th_th)

%             th_type - threshold application method
%	          'hard':	Kill the coeff. under threshold
%		  'soft':	Shrink the coeff under threshold
%		  'linear':	Linear shrinkage

if nargin < 3
  error('Need objects to threshold and threshold type');
end
if nargin < 4
  th_th = [];
end
if isempty(th_bin)
  if ~strcmp(th_type, 'linear')
    error('Need threshold mask to apply this threshold method');
  end
end
if isempty(th_th)
  if ~strcmp(th_type, 'hard')
    error('Need thresholds to apply this threshold method');
  end
end

% apply thresholds
for oi = 1:prod(size(objs))
  obj(oi) = doproc(obj(oi));
  
  suprath = abs(stblk) >= thresh;
  switch dninf.thapp 
   case 'linear'
    stblk = stblk * thresh;
    eblk = eblk * thresh; % error thresholding
   case 'soft'
    gt0 = (stblk(suprath) > 0)*2-1;
    stblk(suprath) = stblk(suprath) - gt0 * thresh;
    stblk(~suprath) = 0;
   case 'hard'
    stblk(~suprath) = 0;
   otherwise
    error('Don''t recognize threshold application type')
  end
end
