function [phiwD] = estimate_wted(phiwD, params)
% do_estimate method - estimates phiwave GLM for SPM99 model
%
% phiwD           - phido_99 design object (containing SPM99 design)
% params          - struct containing fields, specifying options
%                   Only option so far: 
%                   'write_res' - if not 0, write residual images
%
% $Id: estimate_wted.m,v 1.3 2005/05/30 16:52:44 matthewbrett Exp $

def_params = struct('write_res', 1);

if nargin < 2
  error('Need design and images');
end
if nargin < 3
  params = [];
end

params = mars_struct('ffillsplit', def_params, params);

% get SPM design structure
SPM = des_struct(phiwD);
  
% do estimation
SPM = pr_estimate(SPM, [], params);

% We must set SPMid to contain SPM99 string in order for the mardo_99 to
% recognize this as an SPM99 design
SPM.SPMid  = sprintf('SPM99: PhiWave estimation. phido_99 version %s', ...
		     phiwD.cvs_version);

% return modified structure
phiwD = des_struct(phiwD, SPM);

