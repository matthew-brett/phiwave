function img=wt3d(img,varargin)
% wt3d   Discrete Wavelet Transform in 3D.
% FORMAT img=wt3d(img,h,g,k,del1,del2)
% Modified from wt.m from UviWave distribution, which is
% Copyright (C) 1994, 1995, 1996, by Universidad de Vigo 
% 
% img is 3D matrix to transform.  It needs to be of dyadic dimensions 
% h is the LOW pass filter, or cell array of filters
% g is the HIGH pass filter, or cell array of filters
% k is the coarsest scale for the transform
% del1, del2 are optional delay values for H and G respectively
% (see wt.m for more detailed exposition)
% 
% Modifications Matthew Brett 28/6/01
%
% $Id: wt3d.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $ 
  
% -----------------------------------
%    CHECK PARAMETERS AND OPTIONS
% -----------------------------------

if nargin < 4
  error('Need filters and scales');
end
% complain for non dyadic dimensions
sz = [size(img) 1 1 1];
if any(log2(sz)-floor(log2(sz)))
  error('Need dyadic dimensions');
end

% get and check scales info
k = varargin{3};
varargin{3} = [];
if length(img)<2^k 
  disp('The scale is too high. The maximum for the signal is:')
  floor(log2(length(img)))
  return
end

nodims = 3;
dims = 1:nodims;
% make filters into cells, and expand to 3d if necessary
for i = 1:2
  if ~iscell(varargin{i})
    varargin{i} = varargin(i);
  end
  if prod(size(varargin{i}))==1
    varargin{i} = repmat(varargin{i},1,nodims);
  end
end
h = varargin{1};
g = varargin{2};
if nargin > 4 
  if nargin < 6
    error('Need two values for delay, or none')
  end
  dlp = varargin{3}; if length(dlp)==1, dlp = dlp * ones(1,nodims);end
  dhp = varargin{4}; if length(dhp)==1, dhp = dhp * ones(1,nodims);end
end
    
for d = dims
  % Arrange the filters so that they are row vectors.
  h{d}=h{d}'; 
  g{d}=g{d}';

  %--------------------------
  %    DELAY CALCULATION 
  %--------------------------
  if nargin < 5 % delays not passed

    % Calculate delays as the C.O.E. of the filters
    dlp(d)=wtcenter(h{d});
    dhp(d)=wtcenter(g{d});
  end
  if rem(dhp(d)-dlp(d),2)~=0 % difference between them.
    dhp(d)=dhp(d)+1;         % must be even
  end
  
  %------------------------------
  %    WRAPPAROUND CALCULATION 
  %------------------------------
  llp=length(h{d});           	% Length of the lowpass filter
  lhp=length(g{d});            	% Length of the highpass filter.
  
  % The number of samples for the
  % wrapparound. Thus, we should need to 
  % move along any wrapl samples to get the
  % output wavelet vector phase equal to
  % original input phase.
  wrapl(d) =max([lhp,llp,dlp(d),dhp(d)]);	
	
  % get no of zeros to add to end of vector for convolution
  zpad{d} = zeros(1,max(length(h{d}),length(g{d}))-1);
				
end


% Cycle across scales
for i = 1:k				
  % get the data (assumes UviWave ordering)
  for d = dims
    sref{d} = 1:sz(d);
  end
  x = img(sref{1},sref{2},sref{3});

  % do 3D transform

  % cycle across dimensions
  for d = dims
    % break for single value 1
    if sz(d)>1
      % sort out the indexing
      [rc vdims msz si] = deal(sz, dims, ones(size(dims)), sref);
      rc(d) = [];
      vdims(d) = [];
      msz(d) = sz(d);
      [H G L] = deal(h{d}, g{d}, wrapl(d));
      [lps lpe hps hpe] = deal(dlp(d) +1 +L,...
			       dlp(d) +L +sz(d),...
			       dhp(d) +1 +L,...
			       dhp(d) +L +sz(d));
      % loop over rows and columns
      for r = 1:rc(1)
	si{vdims(1)} = r;
	for c = 1:rc(2)
	  si{vdims(2)} = c;
	  t = x(si{1},si{2},si{3});  	        % Copy the vector to transform.
	  t = t(:)';
	  
	  tp=t;		       	% Build wrapparound. The input signal
	  pl=length(tp);	       	% can be smaller than L, so it can
	  while L>pl		% be necessary to repeat it several
	    tp=[tp,t];	% times
	    pl=length(tp);
	  end
	  
	  t=[tp(pl-L+1:pl),t,tp(1:L) zpad{d}];% Add the wrapparound. and zeros
	  
	  yl=filter(H, 1, t);    % Then do lowpass filtering ...
	  yh=filter(G, 1, t);    % ... and highpass filtering.
	  
	  yl=yl(lps:2:lpe);    % Decimate the outputs
	  yh=yh(hps:2:hpe);    % and leave out wrapparound
	  
	  t = reshape([yl yh],msz);
	  x(si{1},si{2},si{3}) = t;    % Wavelet vector (1 row vector)
	end % columns
      end % rows
    end % if sz>1
  end				% End of the "dims" loop.
  img(sref{1},sref{2},sref{3}) = x;

  sz = max([sz / 2;ones(size(sz))]);
end
%------------------------------
%    END OF THE ALGORITHM 
%------------------------------

