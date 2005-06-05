function obj = subsasgn(obj, s, rhs)
% SUBSASGN  Method to overload subsasgn for phiw_wvimg object
%
% $Id: subsasgn.m,v 1.3 2005/06/05 04:37:15 matthewbrett Exp $

if nargin < 3
  error('Crazy no of args')
end

% set change flag
obj.changef = 1;

switch s(1).type
 case '.'
  % do processing if necessary
  if strcmp(s(1).subs, 'img') & length(s)>1 & ~isproc(obj)
    if obj.options.verbose
      warning('Object not yet processed, processing now')
    end
    obj = doproc(obj);
  end
  %   Publicize subscripted reference to private fields of object.
 obj = builtin('subsasgn',obj ,s , rhs);

 case '{}'
  % Cell ref.  Maybe this could insert cells full of the indexed
  % levels/quadrants, but not for now
  error('Cell subscripting not valid for wvimg objects')
  
 case '()'
  % bracket ref.  
  if length(s) > 1
    error('Complicated subscripting')
  end

  if ~isproc(obj)
    if obj.options.verbose
      warning('Object not yet processed, processing now')
    end
    obj = doproc(obj);
  end

  nsubs = length(s.subs);
  if all([s.subs{:}]==':')
    obj.img(:) = rhs(:);
    return
  end
  if nsubs == 3
    obj.img = subsasgn(obj.img,s,rhs);
    return
  end
  [blks s.subs sz] = pr_procsubs(obj.wavelet,obj.wvol.dim(1:3),obj.scales, ...
			       s.subs);
  rhsz = prod(size(rhs));
  if rhsz == 1
    rhs = zeros(1,sum(sz))+rhs;
  elseif rhsz ~= sum(sz)
    error('Not enough rhs to fill quadrants');
  end
  iR = 1;
  for b = 1:length(blks)
    e = iR + sz(b);
    obj.img = subsasgn(obj.img, phiw_lims('subs', blks{b}), ...
		       reshape(...
			   rhs(iR:e-1),...
			   phiw_lims('dims', blks{b})));
    iR = e;
  end
end