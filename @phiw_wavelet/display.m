function display(obj)
% display - placeholder display for phiw_wavelet
%
% $Id: display.m,v 1.1 2004/11/18 18:41:04 matthewbrett Exp $
  
X = struct(obj);
src = descrip(obj);
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