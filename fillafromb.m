function c = fillafromb(a, b,fieldns)
% fills structure fields empty or missing in a from those present in b
% FORMAT c = fillafromb(a, b,fieldns)
% a, b are structures
% fieldns (optional) is cell array of field names to fill from in b
% c is returned structure
% Is recursive, will fill struct fields from struct fields
%
% $Id: fillafromb.m,v 1.1.1.1 2004/06/25 15:20:35 matthewbrett Exp $
  
if nargin < 2
  error('Must specify a and b')
end

c = a;
% Return for empty passed args
if isempty(a)
  c = b;
  return
end
if isempty(b)
  return
end

if nargin < 3
  fieldns = fieldnames(b);
end
if ischar(fieldns), fieldns=cellstr(fieldns);end

af = fieldnames(a);
bf = fieldns;
mfi = ~ismember(bf, af);
for i=1:length(bf)
  bfc = getfield(b,bf{i});
  if mfi(i) | isempty(getfield(a, bf{i})) 
    c = setfield(c, bf{i}, getfield(b, bf{i}));
  else
    afc = getfield(a,bf{i});
    if isstruct(afc) & isstruct(bfc)
      c = setfield(c, bf{i},fillafromb(afc,bfc));
    end
  end
end

return