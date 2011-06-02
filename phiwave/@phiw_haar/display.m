function display(obj)
% display method for phiw_haar
%
% $Id: display.m,v 1.1 2005/07/07 21:24:47 matthewbrett Exp $
  
X = struct(obj);
src = descrip(obj);
if isequal(get(0,'FormatSpacing'),'compact')
  disp([inputname(1) ' =']);
  disp(src);
else
  disp(' ')
  disp([inputname(1) ' =']);
  disp(' ');
  disp(src);
  disp(' ');
end    