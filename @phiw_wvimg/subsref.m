function R = subsref(obj, s)
% SUBSREF Method to overload subscripted references
%
% $Id: subsref.m,v 1.3 2005/06/05 04:37:48 matthewbrett Exp $

if nargin < 2
  error('Crazy no of args')
end

switch s(1).type
 case '.'
  % dump out if processing is not done
  if strcmp(s(1).subs, 'img') & ~isproc(obj)
    error('The object is not processed yet')
  end
  %   Publicize subscripted reference to private fields of object.
  R = builtin('subsref', obj, s);
 case '{}'
  % Cell ref.  Maybe this could return cells full of the indexed
  % levels/quadrants, but not for now
  error('Cell subscripting not valid for wvimg objects')
 case '()'
  % bracket ref.  
  if length(s) > 1
    error('Complicated subscripting')
  end

  % dump out if processing is not done
  if ~isproc(obj)
    error('The object is not processed yet')
  end

  nsubs = length(s.subs);
  if all([s.subs{:}]==':')
    R = obj.img;
    if nsubs ~= 3
      R = R(:);
    end
    return
  elseif nsubs == 3
    R = subsref(obj.img,s);
    return
  end
  [blks s.subs sz] = pr_procsubs(obj.wavelet,obj.wvol.dim(1:3),obj.scales, ...
			       s.subs);
  R = zeros(sum(sz),1);
  iR = 1;
  for b = 1:length(blks)
    e = iR + sz(b);
    R(iR:e-1) = subsref(obj.img, phiw_lims('subs', blks{b}));
    iR = e;
  end
end