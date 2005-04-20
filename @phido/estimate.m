function [phiwD] = estimate(phiwD, VY, params)
% estimate method - estimates phiwave GLM for SPM model
%
% phiwD           - SPM design object
% VY              - Images to estimate on (default - from design)
% params          - structure containing options as fields; [defaults]
%                   'wavelet'    - phiwave wavelet object to transform
%                      images [phiw_lemarie(2)] 
%                   'scales'     - scales for wavelet transform [4]
%                   'wtprefix'   - prefix for wavelet transformed files
%                      ['wv_']
%                   'maskthresh' - threshold for mask image [0.05]
%
% e.g.
% % Estimate using images from design, lemarie wavelet
% params = struct('scales', 4, 'wavelet', phiw_lemarie(2), ...
%                 'wtprefix', 'wt_', 'maskthresh', 0.05); 
% pE = estimate(pD, [], params);
% 
% $Id: estimate.m,v 1.3 2005/04/20 15:10:33 matthewbrett Exp $

% Default parameters
defparams = struct('wavelet',  phiw_lemarie(2), ...
		   'scales',   4, ...
		   'wtprefix', 'wv_', ...
		   'maskthresh', 0.05);

if nargin < 2
  VY = [];
end
if nargin < 3
  params = [];
end

% Images not passed, use images in design
if isempty(VY)
  if ~has_images(phiwD)
    error('Need data in design or passed as argument');
  end
  VY = get_images(phiwD);
else
  % Images passed, check and put in design
  if size(VY, 1) == 1, VY = VY'; end
  if size(VY, 1) ~= n_time_points(phiwD)
    error('The data and design must have the same number of rows');
  end
  phiwD = set_images(phiwD, VY);
end

% check design is complete
if ~can_phiw_estimate(phiwD)
  error('This design needs more information before it can be estimated');
end

% if images in design are wt'ed, get default from there
if phiw_wvimg('is_wted', VY(1))
  defparams  = mars_struct('ffillsplit', defparams,  ...
			   phiw_wvimg('wtinfo', VY(1)));
end
params = mars_struct('ffillsplit', defparams, params);

% check if files are already WT'ed, do WT if not
phiwD = vox2wt_ana(phiwD, params);

% Do estimation
phiwD = estimate_wted(phiwD, params);

