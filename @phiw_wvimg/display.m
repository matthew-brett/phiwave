function display(obj)
% display - placeholder display for wvimg
%
% $Id: display.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $
  
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