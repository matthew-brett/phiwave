function mfcells = matfilerw(mfimgs, varargin)
% gets / sets parameters from / to mat file(s)
% FORMAT mfcells = matfilerw(mfimgs, mfvnames, mfvvals) OR
% FORMAT mfcells = matfilerw(mfimgs, mfstruct) 
%
% mfimgs can be filenames of images, or mat files, or vol structs
% mfvnames is cell array containing names of variables to save
% mfvvals is cell array with same number of columns as the number of
% names in mfvnames, containing values of variables, to save with names
% given in mfvnames.  If has more than one row, should have the same
% number of rows as the number of mat files, with values for each mat
% file in each row
% OR
% mfstruct - (cell array of) structures, fields are variables saved into
% mat file. If more than one element, should have one element of each mat
% file, each with a structure to save into the mat file
%
% values will be appended to current contents of mat file
% NB the mat file will be v5 compatible only if modified here
%
% mfcells is cell array size of mfimgs, with mat file values in structures
%
% Matthew Brett 20/10/00
%
% $Id: matfilerw.m,v 1.2 2004/06/25 16:18:22 matthewbrett Exp $
  
if nargin < 1
  error('Need image / mat file name(s), +/- params to add')
end
if isstruct(mfimgs)  % vol struct to filename
  mfimgs = strvcat(mfimgs(:).fname);
end
mf.nimgs = size(mfimgs, 1);

mfstruct = {};
if nargin == 2  % mfstruct form
  mfstruct = varargin{1};
  if ~iscell(mfstruct), mfstruct={mfstruct};end
end
if nargin > 2  % mfvnames, mfvvals form
  [mfvnames mfvvals] = deal(varargin{1:2});
  if ~iscell(mfvnames), mfvnames = cellstr(mfvnames); end
  if ~iscell(mfvvals), mfvvals = {mfvvals};end
  mfvnames = mfvnames(:);
  nvar = length(mfvnames);
  tmp = [size(mfvvals) == nvar];
  if sum(tmp)==0
    error('Value arrays must have same no of rows or columns as names');
  end
  if all(tmp == [1 0]), mfvvals=mfvvals';end
  nstructs = size(mfvvals,1);
  mfstruct = cell(nstructs,1);
  for r = 1:size(mfvvals,1)  
    for c = 1:nvar
      mfstruct{r} = setfield(mfstruct{r},mfvnames{c},mfvvals{r,c});
    end
  end
end
if isempty(mfstruct)
  nilnewf = 1;
  mfstruct = cell(mf.nimgs,1);
else
  nilnewf = 0;
  mfstruct = mfstruct(:);
  if length(mfstruct)==1
    mfstruct = repmat(mfstruct,mf.nimgs,1);
  elseif length(mfstruct)~=mf.nimgs
    error('Fewer passed values than mat file names');
  end
end
  
mfcells = cell(mf.nimgs, 1);
for mfi = 1:mf.nimgs;
  mf.name = [spm_str_manip(mfimgs(mfi,:), 's') '.mat'];
  mf.ef = exist(mf.name, 'file');
  mfstructi = mfstruct{mfi};
  if mf.ef
    matvars = load(mf.name);
    mfstructi = mars_struct('fillafromb', mfstructi, matvars);
  end
  if ~nilnewf
    savestruct(mf.name, mfstructi);
  end      
  mfcells{mfi} = mfstructi;
end