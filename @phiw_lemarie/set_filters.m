function o = set_filters(o, varargin)
% sets filters for lemarie wavelet
% FORMAT o = set_filters(o, varargin)
% 
% Function has no effect, as filters are determined for each call to
% get_filters for this object
%
% $Id: set_filters.m,v 1.1 2004/09/26 07:48:37 matthewbrett Exp $

if verbose(o)
  warning(['set_filters ignored for ' ...
	  class(o) ' object']);
end

return


