function cdata = pr_classdata(fieldname, value)
% sets/gets class data for wavelet object
% FORMAT cdata = pr_classdata(fieldname, value)
%
% phiw_wvavelet class data is implemented with a persistent variable
% - CLASSDATA.  This is a structure containing fields
%
% wtcentermethod   - centre method for wavelet transform.  Integer in the
%                    range 0:3; see help for center.m for details
%
% Field values can be returned with the call
%    phiw_wavelet('classdata') - which returns the whole structure
% or phiw_wavelet('classdata', fieldname) - which returns field data
%
% Field values can be set with the call
% phiw_wavelet('classdata', fieldname, value) OR
% phiw_wavelet('classdata', struct) where struct contains fields matching
% those in CLASSDATA
%
% The same functionality results from 
% classdata(obj, fieldname) etc.
%
% $Id: pr_classdata.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

persistent CLASSDATA
if isempty(CLASSDATA)
  CLASSDATA = struct(...
      'wtcentermethod', 0);
end

if nargin < 1 % simple classdata call
  cdata = CLASSDATA;
  return
end
if nargin < 2 & ~isstruct(fieldname) % fieldname get call
  if isfield(CLASSDATA, fieldname) 
    cdata = getfield(CLASSDATA,fieldname);
  else 
    cdata = []; 
  end
  return
end

% some sort of set call
if ~isstruct(fieldname) 
  fieldname = struct(struct(fieldname, value));
end
for field = fieldnames(fieldname)
  if isfield(CLASSDATA, field{1})
    CLASSDATA = setfield(CLASSDATA, field{1},...
				    getfield(fieldname, field{1}));
  end
end
cdata = CLASSDATA;