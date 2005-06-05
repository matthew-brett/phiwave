function write_descrip(obj, fname)
% writes description text file for object to fname 
%
% $Id: write_descrip.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

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