function [errf, msg] = pr_check_filters(filt)
% checks filter structure, returns error, msg if problem
% FORMAT [errf, msg] = pr_check_filters(filt)
% 
% $Id: pr_check_filters.m,v 1.1 2004/09/26 03:54:16 matthewbrett Exp $
  
if nargin < 1
  error('Need filter to check');
end

errf = 1; msg = '';
fns = {'H', 'G', 'RH', 'RG'};

if ~isstruct(filt)
  msg = ['Filter should be structure with fields ' ...
	 sf_strcat(fns)];
  return
end

[filt others] = mars_struct('split', filt, fns);
out_fns = fieldnames(others);
if ~isempty(out_fns)
  msg = ['Do not recognize filter fieldname(s) ', ...
	 sf_strcat(out_fns)];
  return
end
out_fns = fns(~ismember(fns, fieldnames(filt)));
if ~isempty(out_fns)
  msg = ['Filter fieldnames missing: ', ...
	 sf_strcat(out_fns)];
  return
end
errf = 0;
return

function str = sf_strcat(strs)
str = sprintf('%s, ', strs{1:end-1});
str = [str strs{end}];
return