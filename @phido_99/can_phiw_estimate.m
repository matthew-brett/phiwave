function tf = can_phiw_estimate(D)
% method returns 1 if design can be estimated in PhiWave
% 
% $Id: can_phiw_estimate.m,v 1.1 2004/11/18 18:37:28 matthewbrett Exp $

tf = ~is_fmri(D) | has_filter(D);

  