function phiw_display(varargin)
% displays activation image on structural image
% FORMAT phiw_display(action, disptype, vols, phiw, defyn)
%
% Inputs [default]
% action          - 'display' or 'orthcb'
% disptype        - 'orth' orthoviews or 'slices' slice view ['orth']
% vols            - string or struct for either: activation image or
%                   structural image followed by activation image [GUI]
% phiw            - struct with various display defaults [PHI]
% defyn           - flag, if set, use all default display settings [1]
%
% Matthew Brett 10/10/00
%
% $Id: phiw_display.m,v 1.2 2004/06/25 16:18:22 matthewbrett Exp $
  
[action disptype vols phiw defyn] = argfill(...
    varargin, 0,{'display', 'orth', [],[],[]}, 1);
switch lower(action)
case 'display'
disptype = lower(disptype);
if ~ismember(disptype, {'orth', 'slices'})
  error('Don''t recognize display type');
end
phiw = phiw_options('fill',phiw, spm('getglobal', 'PHI'));
if isempty(vols)
  vols = spm_get(1, 'img', 'Activation image to display');
end
if ischar(vols), vols = spm_vol(vols);end
if length(vols)>1 % assume 1st image is structural, 2nd functional
  actvol = vols(2);
  structv = vols(1);
else
  actvol = vols;
  structv = [];
end

[Finter,Fgraph,CmdLine] = spm('FnUIsetup','Display functional image');
  
cmap=[];
if isempty(defyn)
  defyn = spm_input('Display type', '+1', 'b', 'Default|Custom', [1 0], 1);
end
if ~defyn
  if isempty(structv),
    tmp = spm_input('Structural', '+1', 'b', 'Default|Custom', [0 1], 1);
    if tmp
      simg = spm_get([0 1], 'img', 'Structural for display');
      if isempty(simg), return, end
      structv = spm_vol(simg);
    end
  end
  if ~isempty(structv)
    [mx mn] = slice_overlay('volmaxmin', structv);
    phiw.structural.range = spm_input('Img range for structural','+1', 'e', [mn mx], ...
		       2);
  end
  tmp = spm_input('Colormap for contrast', '+1', 'b', 'Default|Custom', ...
		  [0 1], 1);
  if tmp
    ypos = spm_input('!NextPos');
    while isempty(cmap)
      [cmap w]= slice_overlay('getcmap',...
			      spm_input('Activation colormap',ypos,'s', ...
					phiw.display.cmapname));
      if isempty(cmap), disp(w);end
    end
  end
  phiw.display.actprop = spm_input('Activation intensity',...
		      '+1', 'e',phiw.display.actprop);

  if strcmp(disptype, 'slices')
    phiw.display.transform = deblank(spm_input('Image orientation', '+1', ...
				     ['Axial|Coronal|Sagittal'], ...
				     strvcat('axial','coronal', ...
					     'sagittal'),1));
    % slices for display
    phiw.display.slices = spm_input('Slices to display (mm)', '+1', 'e', ...
			  sprintf('%0.0f:%0.0f:%0.0f',...
				  min(phiw.display.slices),...
				  mean(diff(phiw.display.slices)),...
				  max(phiw.display.slices)));
  end
else % if defyn==1
  if ~isempty(structv)
    [mx mn] = slice_overlay('volmaxmin', structv);
    phiw.structural.range = [mn mx];  
  end
end
if isempty(structv)
  structv = spm_vol(phiw.structural.fname);
end
if isempty(cmap)
  cmap = slice_overlay('getcmap', phiw.display.cmapname);
end

% Range for cmap
[mx mn] = slice_overlay('volmaxmin', actvol);
amx = max(abs([mx mn]));
range = [-amx amx];
promptstr = sprintf('Range for cmap %0.2f:%0.2f',mn,mx); 
finf = 0;
while ~finf
  range = spm_input(promptstr,'+1', 'e', range, 2);
  finf = diff(range);
end

switch lower(disptype)
 case 'orth'
  global st
  spm_image('init', structv.fname);
  spm_orthviews('Addtruecolourimage', 1, actvol.fname, cmap, phiw.display.actprop, ...
		range(2), range(1));
  st.callback = 'phiw_display(''orthcb'');';
 case 'slices'
  clear global SO
  global SO
  SO.img(2) = struct(...
      'type', 'truecolour',...
      'prop', 1-phiw.display.actprop,...
      'range', phiw.structural.range,...
      'vol', structv,...
      'cmap', gray);
  SO.img(1) = struct(...
      'type', 'truecolour',...
      'prop', phiw.display.actprop,...
      'range', range,...
      'vol', actvol,...
      'cmap', cmap);
  SO.cbar = 1;
  SO.slices=phiw.display.slices;
  SO.transform=phiw.display.transform;

  % use SPM figure window, and display
  SO.figure = spm_figure('GetWin', 'Graphics'); 
  slice_overlay;
 
 otherwise
  error('Don''t recognize display type');
end
case 'orthcb'
% callback function from spm_orthviews, gives activation rather than
% structural intensity in text box.  Copied from spm_image.m  
global st
if isfield(st,'mp'),
  fg = spm_figure('Findwin','Graphics');
  if any(findobj(fg) == st.mp),
    set(st.mp,'String',sprintf('%.1f %.1f %.1f',spm_orthviews('pos')));
    pos = spm_orthviews('pos',1);
    set(st.vp,'String',sprintf('%.1f %.1f %.1f',pos));
    if isfield(st.vols{1}, 'blobs') & isfield(st.vols{1}.blobs{1}, 'vol')
      pos = st.vols{1}.blobs{1}.mat \ st.vols{1}.mat * [pos; 1];
      ival = spm_sample_vol(st.vols{1}.blobs{1}.vol,pos(1), pos(2),pos(3),st.hld);
    else
      ival = spm_sample_vol(st.vols{1},pos(1), pos(2),pos(3),st.hld);
    end
    set(st.in,'String',sprintf('%g',ival));
  else,
    st.Callback = ';';
    rmfield(st,{'mp','vp','in'});
  end;
else,
  st.Callback = ';';
end;

otherwise
 error('Can''t recognize action string')
end;

return