function [inplevs, quads, nquads] = levels(w, odim, scales)
% levels - returns indices for levels, quadrants for data size odim
% FORMAT [inplevs, quads] = levels(w, odim, scales)
% w      - wavelet
% odim   - dimension of wavelet transformed data
% scales - number of scales used by wavelet transform
% 
% returns
% inplevs - index limits for each scale, before xform, within the matrix size (odim)
% quads  - scales by quadrants cell matrix giving index limits for 
%          quadrants (at each scale) from wt
% nquads - no of quadrants
%
% This template wavelet function assumes dyadic dimensions
%
% $Id: levels.m,v 1.2 2004/11/18 19:02:25 matthewbrett Exp $
  
if nargin < 3
  error('Need odim and scales to return level info');
end

% defining quadrants per level
ndims = length(odim);
nquads = 2^ndims;
qs = 0:(nquads-1); 
% flag to note that detail coefficients go to 
% right of data vector (as for UviWave)
if w.detail_right, qs = fliplr(qs); end

% get quadrants (including low) by analogy to ind2sub for 
% matrix of size ones(ones(1,ndims)*2)
dsz = 2.^(0:ndims-1); % dimension sizes
for dim = ndims:-1:1
  quad_add(:,dim) = floor(qs/dsz(dim))';
  qs = rem(qs,dsz(dim));
end

bdim = odim;
stpos = ones(1,ndims);
quads = cell(scales+1,1);
inplevs = cell(scales+1,1);
inplevs{1} = [ones(1, ndims);odim];
for l=1:scales
  bdim = bdim / 2;
  tdim = [zeros(1,ndims);bdim-1];
  stadd = [1;1] * stpos;
  for q=1:nquads-1;
    qm{q} = stadd + tdim + [1;1]*((quad_add(q,:).*bdim));
  end
  quads{l} = qm;
  % move to next low origin
  stpos = stpos + (quad_add(nquads,:).*bdim);
  % and store in levels matrix
  inplevs{l+1} = [1;1] * stpos + tdim;
end
% lowest pass level
quads{scales+1}(1) = inplevs(scales+1);