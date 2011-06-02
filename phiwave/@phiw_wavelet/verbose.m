function res = verbose(o, val)
% gets/sets verbose flag for phiw_wavelet object
% FORMAT (get) val = verbose(o);
% FORMAT (set) o   = verbose(o, val);
% 
% $Id: verbose.m,v 1.1 2004/09/26 07:49:12 matthewbrett Exp $ 
  
if nargin < 2
  % get
  res = o.verbose;
else
  % set
  o.verbose = val;
  res = o;
end