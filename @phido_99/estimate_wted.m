function [phiwD] = do_estimate(phiwD, params)
% do_estimate method - estimates phiwave GLM for SPM99 model
%
% phiwD           - phido_99 design object (containing SPM99 design)
% params          - struct containing options (not used for now)
%
% $Id: estimate_wted.m,v 1.1 2004/11/18 18:38:18 matthewbrett Exp $

if nargin < 2
  error('Need design and images');
end
if nargin < 3
  params = [];
end

% get SPM design structure
SPM = des_struct(phiwD);
  
% do estimation
SPM = pr_estimate(SPM);

% We must set SPMid to contain SPM99 string in order for the mardo_99 to
% recognize this as an SPM99 design
SPM.SPMid  = sprintf('SPM99: PhiWave estimation. phido_99 version %s', ...
		     phiwD.cvs_version);

% return modified structure
phiwD = des_struct(phiwD, SPM);

