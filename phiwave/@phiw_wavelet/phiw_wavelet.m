function [o, others] = phiw_wavelet(params, varargin)
% class constructor for phiw_wavelet object
% FORMAT [o, others] = phiw_wavelet(params, varargin)
%
% Synopsis
% --------
% o = phiw_wavelet;
% 
% % Imagine you have set variables H G RH RG to be analysis low, high pass
% % synthesis low, high pass filters respectively
% o = phiw_wavelet(struct('H', H, 'G', G, 'RH', RH, 'RG', RG));
% 
% % Or to access classdata (see classdata method)
% res = maroi('classdata', 'wtcentermethod'); 
%
% Inputs [defaults]
% params  - maybe a filter structure containing fields
%              H  - analysis low pass   [1]
%              G  - analysis high pass  [1]
%              RH - synthesis low pass  [1]
%              RG - synthesis high pass [1]
%            OR
%              structure containing field 'filters' as above, and any other
%              object fields - see below for other object fields
%            OR 
%              string specifying class function - one of
%              - classdata: get or set class data
%   
% varargin - if first argument was string, then varargin represent input
% to class function calls.  Otherwise varargin will be one argument:
%
% others   - optional structure with any other fields for the object
%            Fields can be 
%             - detail_right - flag, if == 1 specifies detail coeffs to
%                              right of vector (UviWave) [1]
%             - verbose      - flag, if == 1, gives messages sometimes
%             - wtcentermethod - method to determine wavelet centre
%                                method, see center.m function for
%                                definitions.  Can be integer from 0 to 3
%
% As usual, any unrecognized fields in input structures are passed out
% for other (child) objects to parse if they like
%
% $Id: phiw_wavelet.m,v 1.6 2005/06/05 04:42:22 matthewbrett Exp $

myclass = 'phiw_wavelet'; 

if nargin < 1
  params = [];
end

% parse out string action calls (class data, helper functions)
if ischar(params)
  switch params
   case 'classdata'
    o = pr_classdata(varargin{:});
   otherwise
    error(['Do not recognize action string ' params]);
  end
  return
end

% Default object structure
cvs_v   = mars_cvs_version(myclass);
wtcm = phiw_wavelet('classdata', 'wtcentermethod');
defstruct = struct('filters', struct('H',1,'G',1,'RH',1,'RG',1),...
		   'detail_right', 1, ...
		   'verbose', 1, ...
		   'wtcentermethod', wtcm);

if nargin < 1
  defstruct.cvs_version = cvs_v;
  o = class(defstruct, myclass);
  others = [];
  return
end

if nargin < 2
  others = [];
else
  others = varargin{1};
end

if isa(params, myclass)
  o = params;
  % Check for simple form of call
  if isempty(others), return, end

  % Otherwise, we are being asked to set fields of object
  [p others] = mars_struct('split', others, defstruct);
  if isfield(p, 'filters'), o = set_filters(o, p.filters); end
  if isfield(p, 'detail_right'), o.detail_right = p.detail_right; end
  if isfield(p, 'verbose'), o.verbose = p.verbose; end
  if isfield(p, 'wtcentermethod'), o.wtcentermethod = p.wtcentermethod; end
  return
end

% Check params input argument
if isfield(params, 'H'), params = struct('filters', params); end
filt = mars_struct('getifthere', params, 'filters');
if isempty(filt), error('Need filters as input'); end
[errf msg] = pr_check_filters(filt);
if errf, error(msg); end

% Fill with other params, defaults
% Parse into fields for this object,children
params = mars_struct('ffillmerge', params, others);
[params, others] = mars_struct('ffillsplit', defstruct, params);

params.cvs_version = cvs_v;

% set the phiw_wavelet object
o  = class(params, myclass);

return