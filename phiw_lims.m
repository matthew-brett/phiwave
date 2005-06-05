function r = phiw_lims(action, lims, type)
% multifunction function to process limit values
% Limits are beginning, end index pairs for matrix dimensions
% 
% Inputs
% action      - action string
% lims        - index limits, 2 by number of matrix dimensions
% type        - maybe necessary third argument...
%
% Output
% r           - its the output
%
% FORMAT s = phiw_lims('to_subs', lims, type)
% returns subs struct for limits given in lims matrix useful in indexing in
% subsasgn, subsref
%
% FORMAT szs = phiw_lims('size', lims)
% returns data size for limits given in lims matrix
%
% FORMAT dims = phiw_lims('dims', lims)
% returns data dimensions for limits limits given in lims matrix
%
% $Id: phiw_lims.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $
  
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