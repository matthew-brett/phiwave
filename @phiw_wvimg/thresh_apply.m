function [objs] = thresh_apply(objs, th_obj, dndescrip)
% apply thresholding calculated previously 
% FORMAT [objs] = thresh_apply(objs, th_obj, dndescrip)
% 
% Inputs
% objs       - wv_img objects to apply thresholding to
% th_obj     - thresholding wv_img object from thresh_calc
% dndescrip  - optional denoising description string
% 
% Outputs
% objs       - thresholded objects
%
% $Id: thresh_apply.m,v 1.2 2005/05/30 16:43:30 matthewbrett Exp $ 

if nargin < 2
  error('Need objects to threshold and threshold object');
end
if nargin < 3
  dndescrip = [];
end

% get whole thresholding object as image
th_obj = doproc(th_obj);
th_img = th_obj.img;
clear th_obj;

% apply thresholds
for oi = 1:prod(size(objs))
  obj = objs(oi);
  obj = doproc(obj);
  in_mask = isfinite(obj.img);
  obj.img(in_mask) = obj.img(in_mask) ./ th_img(in_mask);
  obj.descrip = strvcat(obj.descrip, dndescrip);
  objs(oi) = obj;
end
