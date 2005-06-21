function tf = can_phiw_estimate(D)
% method returns 1 if design can be estimated in Phiwave
% 
% $Id: can_phiw_estimate.m,v 1.2 2005/06/21 15:18:13 matthewbrett Exp $

tf = ~is_fmri(D) | has_filter(D);

  