function write_descrip(obj, fname)
% write_descrip - writes description text file
%
% $Id: write_descrip.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

if nargin < 2
  fname = obj.wvol.fname;
end
if isstruct(fname)
  fname = fname.fname;
end
if isempty(fname)
  error('Could not find a filename');
end

% add descrip.txt to .img/hdr fnames
[p f e] = fileparts(fname);
if any(strcmp(e, {'.img','.hdr'}))
  fname = fullfile(p, [f '_descrip.txt']);
end

d = cellstr(obj.descrip);
if ~isempty(d)
  fid = fopen(fname,'wt');
  if fid ~= -1
    fprintf(fid,'%s\n',d{:});
    fclose(fid);
  end
end