function display(obj)
% placeholder display for wvimg object
%
% $Id: display.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $
  
X = struct(obj);
src = ['[phiw_wvimg object - ' wvfname(obj) ']'];
if isequal(get(0,'FormatSpacing'),'compact')
  disp([inputname(1) ' =']);
  disp(src);
  disp(X)
else
  disp(' ')
  disp([inputname(1) ' =']);
  disp(' ');
  disp(src);
  disp(' ');
  disp(X)
end    