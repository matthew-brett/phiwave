function r = phiw_lims(action, lims, type)
% process limit values 
%
% FORMAT s = phiw_lims('to_subs', lims, type)
% returns subs struct for limits given in lims matrix (2 by no of
% dimensions) useful in indexing in subsasgn, subsref
%
% FORMAT szs = phiw_lims('size', lims)
% returns data size for limits limits given in lims matrix (2 by no of
% dimensions)
%
% FORMAT dims = phiw_lims('dims', lims)
% returns data dimensions for limits limits given in lims matrix (2 by no of
% dimensions)
%
% $Id: phiw_lims.m,v 1.1 2005/06/01 09:32:34 matthewbrett Exp $
  
if nargin < 1
  error('Need action');
end
if nargin < 2
  error('Need lims');
end

switch lower(action)
  case 'subs'
   if nargin < 3, type = '()'; end
   [t n] = size(lims);
   r = struct('type', type);
   for d = 1:n
     r.subs{d} = lims(1,d):lims(2,d);
   end
 case 'size'
  if isempty(lims), r = 0; return, end
  r = 1;
  [t n] = size(lims);
  for d = 1:n
    r = r * (lims(2,d)-lims(1,d)+1);
  end
 case 'dims'
  if isempty(lims), r = 0; return, end
  r = lims(2,:)-lims(1,:)+1;
 otherwise
  error(['Wild request for ' action]);
end