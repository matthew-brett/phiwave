function [dlp, dhp] = pr_synth_delay(rh, rg, del1, del2)
% work out delays for synthesis filters
% FORAMT [dlp, dhp] = pr_synth_delay(rh, rg, del1, del2)
% 
% rh     - low pass filter
% rg     - high pass filter
% del1   - delay for analysis low pass filter
% del2   - delay for analysis high pass filter
% 
% Returns
% dlp    - synthesis low pass delay
% dhp    - synthesis high pass delay
%
% Based on bits of iwt from UviWave with thanks
% 
% $Id: pr_synth_delay.m,v 1.1 2004/07/08 04:31:35 matthewbrett Exp $

if nargin < 2
  error('Need synthesis filters');
end
  
%--------------------------
%    DELAY CALCULATION 
%--------------------------

llp=length(rh);		% Length of the lowpass filter.
lhp=length(rg);		% Length of the highpass filter.

suml = llp+lhp-2;		% The total delay of the
difl = abs(lhp-llp);		% analysis-synthesis process
if rem(difl,2)==0		% must match the sum of the  
	suml = suml/2;		% analysis delay plus the synthesis  
end;				% delay. SUML holds this total
				% delay, which is different depending
				% on the kind of filters. 

% Calculate analysis delays as the reciprocal M. C.
dlpa=wtcenter(rg);
dhpa=wtcenter(rh);

if rem(dhpa-dlpa,2)~=0		% difference between them.
	dhpa=dhpa+1;		% must be even
end;

if nargin==4,			% Other experimental filter delays
	dlpa=del1;		% can be forced from the arguments,
	dhpa=del2;	
end;

dlp = suml - dlpa;		% Found the analysis delays, the 
dhp = suml - dhpa;		% synthesis are the total minus the
				% analysis ones.
