function [phiwD] = estimate(phiwD, VY, params)
% estimate method - estimates phiwave GLM for SPM model
%
% phiwD           - SPM design object
% VY              - Images to estimate on (default - from design)
% params          - structure containing options as fields; at least
%                     wtinfo - wavelet info (wavelet, scales)
%
% e.g.
% % Estimate using images from design, lemarie wavelet
% wtinfo = struct('scales', 4, 'wavelet', phiw_lemarie(2), ...
%                 'wtprefix', 'wt_'); 
% pE = estimate(pD, [], struct('wtinfo', wtinfo));
% 
% $Id: estimate.m,v 1.1 2004/11/18 18:33:08 matthewbrett Exp $

if nargin < 2
  VY = [];
end

% Images not passed, use images in design
if isempty(VY)
  if ~has_images(phiwD)
    error('Need data in design or passed as argument');
  end
else
  % Images passed, check and put in design
  if size(VY, 1) == 1, VY = VY'; end
  if size(VY, 1) ~= n_time_points(phiwD)
    error('The data and design must have the same number of rows');
  end
  phiwD = set_images(phiwD, VY);
end

if nargin < 3
  params = [];
end
if ~isfield(params, 'wtinfo'), error('Need wtinfo in params struct'); end

% check design is complete
if ~can_phiw_estimate(phiwD)
  error('This design needs more information before it can be estimated');
end

% check if files are already WT'ed, do WT if not
phiwD = vox2wt_ana(phiwD, params.wtinfo);

% Do estimation
phiwD = estimate_wted(phiwD, params);

