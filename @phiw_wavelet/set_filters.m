function o = set_filters(o, H, G, RH, RG)
% sets filters for template wavelet
% FORMAT o = set_filters(o, H, G, RH, RG)
% OR
% FORMAT o = set_filters(o, filter_struct);
% Where filter_struct contains (only) the fields H G RH RG
%
% $Id: set_filters.m,v 1.1 2004/09/26 03:53:27 matthewbrett Exp $

switch nargin
  case 2
   if ~isstruct(H)
     error(['set_filters with 2 input arguments needs a filter structure' ...
	    ' as second input']);
   end
   [errf msg] = pr_check_filters(H);
   if errf, error(msg); end
   o.filters = H;
 case 5
  o.filters = struct('H',  H, ...
		     'G',  G, ...
		     'RH', RH, ...
		     'RG', RG);
 otherwise
  error(['Needs either: object and filter structure, or ' ...
	 'object and high, low pass analysis and synthesis filters']);
end
return


