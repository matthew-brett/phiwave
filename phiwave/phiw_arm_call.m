function [o,errf,msg] = phiw_arm_call(action, o, item, old_o)
% services callbacks from marmoire object set functions
% FORMAT [o,errf,msg] = phiw_arm_call(action, o, item)
% See documentation for marmoire object for more detail
%
% action     - action string
% o          - candidate object for checking etc
% item       - name of item that has just been set
% old_o      - object before set
%
% Returns
% o          - possibly modified object
% errf       - flag, set if error in processing
% msg        - message to examplain error
%
% $Id: phiw_arm_call.m,v 1.1 2005/05/31 23:36:35 matthewbrett Exp $
  
if nargin < 1
  error('Need action');
end
if nargin < 2
  error('Need object');
end
if nargin < 3
  error('Need item name');
end
if nargin < 4
  error('Need old object');
end

errf = 0; msg = ''; 

item_struct = get_item_struct(o, item);

switch lower(action)
 case 'set_design'
  % callback for setting design

  % Check for save of current design
  [btn o] = save_item_data_ui(old_o, 'def_design', ...
			      struct('ync', 1, ...
				     'prompt_prefix','previous '));
  if btn == -1
    errf = 1; 
    msg = 'Cancelled save of previous design'; 
    return
  end
  
  % Make design into object, do conversions
  [item_struct.data errf msg] = sf_check_design(item_struct.data);
  if errf, o = []; return, end
  o = set_item_struct(o, item, item_struct);
  
 case 'set_results'
  % callback for setting results 

  % Need to set default data from results, and load contrast file
  % if not present (this is so for old MarsBaR results)

  data = item_struct.data;
  if isempty(data), return, end
  
  % Check for save of current design
  [btn o] = save_item_data_ui(old_o, 'est_design', ...
			      struct('ync', 1, ...
				     'prompt_prefix','previous '));
  if btn == -1
    errf = 1;
    msg = 'Cancelled save of current design'; 
    return
  end

  % Make design into object, do conversions
  [data errf msg] = sf_check_design(data);
  if errf, return, end
  if ~is_phiw_estimated(data)
    error('Design has not been estimated')
  end
  
  % Put data into object
  item_struct.data = data;
  o = set_item_struct(o, item, item_struct);
  
 otherwise
  error(['Peverse request for ' action]);
end

function [d,errf,msg] = sf_check_design(d)
% Make design into object, do conversions
errf = 0; msg = {};
d = phido(d);
if ~is_valid(d)
  errf = 1; 
  msg = 'This does not appear to be a valid design';
end
return

