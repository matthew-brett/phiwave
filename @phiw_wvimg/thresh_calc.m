function [th_obj, dndescrip] = thresh_calc(wtobj,errobj,statinf,dninf)
% calculate thresholding from wt'ed statistic volumes
% FORMAT [th_obj, dndescrip] = thresh_calc(wtobj,errobj,statinf,dninf)
%
% Threshold calculation assumes that a t statistic is made by dividing the
% data in the phiw_wvimg object wtobj by that in errobj.  We need both the
% numerator and the denominator because we may want to pool the error over
% levels.
%
% Inputs 
%   wtobj   - top half of t statistic
%   errobj  - bottom half (error) of t statistic
%   statinf - structure with information on generated statistic
%             containing fields
%             .stat  - statistic type 'T' or 'Z' or 'TZ' (t to Z
%             transform)
%             .df    - degrees of freedom for T statistic
%   dninf    - structure with information on denoising to be done
%             containing fields
%             .levels  - levels to threshold; should be a vector of
%                length wtobj.scales+1, with a value for each scale: 
%                value = 1 - apply thresholding to this level
%                value = 0 - suppress all coeffs for this level
%                value = -Inf - omit thresholding for this level
%             .thlev - level of thresholding; one of:
%                'image' - whole image (excluding omitted etc levels)
%                'level' - level by level
%                'quadrant' - by quadrant
%             .ncalc - calculation of number of null hypotheses per thlev
%                 block; can be:
%                 'n'      - number of non zero coefficients
%                 'pplot'  - number calculated using pplot algorithm
%             .thcalc - threshold calculation method  
%   		  'visu':	MinMax threshold
%		  'sure':	SURE thresholding (needs soft thresholding)
%		  'stein':      linear Stein
%		  'bonf':	Bonferroni correction
%		  'fdr':	false discovery rate correction
%		  'hoch':	Hoch correction
%             .thapp - threshold application method
%                 'hard'        all cooefficients under thresh = 0
%                 'soft'        sign(y)(abs(y)-thresh)_+
%                 'linear'      y*thresh
%             .alpha - alpha level for p value threshold methods
%             .varpoolf - flag, if non zero, apply variance pooling
%
% Outputs
%   th_obj     - wv_img object with thresholding
%   dndescrip  - text description of denoising applied
%
% Matthew Brett 2/6/2001, Federico E. Turkheimer 17/9/2000
%
% $Id: thresh_calc.m,v 1.4 2005/06/01 00:06:10 matthewbrett Exp $

if nargin < 2
  error('Need at least top and bottom of t statistic, sorry');
end
if nargin < 3
  statinf = [];
end
if nargin < 4
  dninf = [];
end

% load objects
wtobj = doproc(wtobj);
errobj = doproc(errobj);

% Make object for return
th_obj = wtobj;

% check stat structure
defstat = struct('stat','Z','df',10000);
statinf = mars_struct('ffillsplit', defstat,  statinf);

% check denoise structure
defdn = struct('levels',ones(1,wtobj.scales+1),...
	       'thlev','level',...
	       'ncalc','n',...
	       'thcalc','sure',...
	       'thapp','soft',...
	       'varpoolf',0,...
	       'alpha',0.05);
dninf = mars_struct('ffillsplit', defdn, dninf);
if length(dninf.levels) ~= wtobj.scales+1
  error('Unexpected length of levels spec')
end
if strcmp(dninf.thcalc,'sure') & ~strcmp(dninf.thapp,'soft')
  error('sure calculation requires soft thresholding')
end
% apply level thresholding options if present
if isfield(dninf,'lettop') & ~isempty(dninf.lettop) & dninf.lettop > 0
  dninf.levels((end-dninf.lettop+1):end) = -Inf;
end
if isfield(dninf,'killbot') & ~isempty(dninf.killbot) & dninf.killbot > 0
  dninf.levels(1:(dninf.killbot)) = 0;
end

% remove NaNs
wtobj.img(isnan(wtobj.img)) = 0;

% apply levels matrix
suplevs = find(dninf.levels==0);
if ~isempty(suplevs)
  wtobj = subsasgn(wtobj,struct('type','()','subs',{{suplevs}}),0);
end
letlevs = find(dninf.levels==-Inf);
dolevs = find(dninf.levels==1);

% determine blocks
quads = 1:7;
switch dninf.thlev
 case 'image'
  l{1} = dolevs;
  q{1} = quads;
 case 'level'
  l = num2cell(dolevs);
  q{1} = quads;
 case 'quadrant'
  l = num2cell(dolevs);
  q = num2cell(quads);
 otherwise
  error('Don''t recognize level specification');
end  

% number of blocks
lq = length(q);
nblks = length(l) * lq;
% take into account fewer blocks for top level
if lq > 1 & any(dolevs == wtobj.scales+1)
  nblks = nblks - lq + 1;
end

% alpha level Bonferroni corrected for no of blocks
alpha = dninf.alpha / nblks;

% flag for p value calculation
if strcmp(dninf.ncalc,'pplot') | ...
  any(strcmp(dninf.thcalc,{'hoch','fdr'}))
  pvalf = 1;
else
  pvalf = 0;
end

% cycle over blocks to do denoising
for li = 1:length(l)
  if l{li} > wtobj.scales
    % at top level -> only one quadrant
    q = {1};
  end
  for qi = 1:length(q)
    s = struct('type','()','subs',{{l{li},q{qi}}});
    % get data
    dblk = subsref(wtobj, s);
    eblk = subsref(errobj, s);
    full_thblk = zeros(size(dblk));
    
    idx = isfinite(dblk) & dblk~= 0 & isfinite(eblk) & eblk ~=0;
    if ~any(idx), break,end
    eblk = eblk(idx);
    
    % implement pooled variance estimate
    if dninf.varpoolf
      ncoeff = length(eblk);
      eblk  = sqrt(sum(eblk.^2) / ncoeff);
      df = statinf.df * ncoeff;
    else
      df = statinf.df;
    end
    
    % Process on stat type
    stat = statinf.stat;
    stblk = dblk(idx) ./ eblk;
    if ~strcmp(stat, 'Z') & df > 1000, stat = 'Z'; end    
    if strcmp(stat, 'TZ')
      % do T to Z transform 
      stblk = spm_t2z(stblk, df);
    end
    
    % calculate statistic and p values
    if pvalf
      if stat == 'T'
	pblk = spm_Tcdf(-abs(stblk),df)*2;
      else
	pblk = spm_Ncdf(-abs(stblk))*2;
      end	
      [pblk pidx] = sort(pblk);
    end
    
    % do null coeff calc
    switch dninf.ncalc
     case 'n'
      n = length(stblk);
     case 'pplot'
      n = pplot(pblk,alpha,1);
     otherwise
      error('Don''t recognize ncalc method')
    end
    
    % find thresholds
    switch dninf.thcalc
     case 'sure'
      crit = log2(n).^(3/2)./sqrt(n);
      ss   	=   sum(stblk.^2-1)/n;
      if(ss<=crit)
	thresh =sqrt(2*log(n));
      else
	thresh =min([ValSUREThresh(stblk') sqrt(2*log(n))]); 
      end 
     case 'stein'                     	
      thresh = 1-n/sum(stblk.^2);
      thresh = thresh *sign(thresh);
     case 'visu'
      thresh = sqrt(2*log(n));
     case 'bonf'
      if stat == 'T'
	thresh = -spm_invTcdf(alpha/2/n,df);
      else
	thresh = -spm_invNcdf(alpha/2/n);
      end
     case 'hoch'
      H = hoch(pblk,alpha,n,1);
      thresh = min([Inf,min(abs(stblk(pidx(logical(H)))))]);
     case 'fdr'
      H = fdr(pblk,alpha,n,1);
      thresh = min([Inf,min(abs(stblk(pidx(logical(H)))))]);
     otherwise 
      error('Don''t recognize threshold calculation')
    end
    
    % apply thresholding to t image
    switch dninf.thapp 
     case 'linear'
      thblk = stblk * thresh;
     case 'soft'
      thblk = sign(stblk) .* max(0,(abs(stblk)-thresh));
     case 'hard'
      thblk = stblk;
      thblk(abs(thblk) < thresh) = 0;
     otherwise
      error('Don''t recognize threshold application type')
    end
    full_thblk(idx) = thblk ./ stblk;
    
    % restore data to object
    th_obj = subsasgn(th_obj,s,full_thblk);
    
  end
end

% description of denoising
dndescrip = ['Denoising by ' dninf.thlev ...
	     '; null hypothesis calc = ' dninf.ncalc ...
	     '; threshold calc = ' dninf.thcalc ...;
	     '; threshold app = ' dninf.thapp ];
if any(strcmp(dninf.thcalc,{'fdr','hoch','bonf'}))
  dndescrip = strvcat(dndescrip, ['Alpha level: ' num2str(dninf.alpha)]);
end
if ~isempty(suplevs)
  strvcat(dndescrip, [num2str(suplevs) ' levels suppressed']);
end
if ~isempty(letlevs)
  strvcat(dndescrip, [num2str(letlevs) ' levels not thresholded']);
end

th_obj.descrip = strvcat(th_obj.descrip,dndescrip);
