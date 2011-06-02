function tf = is_phiw_estimated(phiwD)
% returns 1 if has been estimated in phiwave
% 
% $Id: is_phiw_estimated.m,v 1.1 2004/11/18 18:33:51 matthewbrett Exp $

SPM = des_struct(phiwD);
tf = mars_struct('getifthere', SPM, 'xPhi', 'estimated');
if isempty(tf), tf = 0; end