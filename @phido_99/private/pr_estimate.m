function SPM = pr_estimate(SPM, VY)
% Wavelet analysis enabled version of spm_spm.m
% Estimation of the General Linear Model
% FORMAT SPM = pr_estimate(SPM, VY)
%
% Based on:
% @(#)spm_spm.m	2.37 Andrew Holmes, Jean-Baptiste Poline, Karl Friston 99/11/26
% 
% The primary differences from the SPM99 version are:
% 1) No smoothness estimation (and no RPV output image)
% 2) Output file name is [wtprefix 'phiw_spm.mat']
% 3) Beta, ResMS image have wtprefix appended
% 4) xCon is not saved separately, but in output file
% 5) Design returned in SPM output structure
%
% VY    - nScan x nVar struct array of mapped image volumes
%         Images must have the same orientation, voxel size and data type
%       - Any scaling should have already been applied via the image handle
%         scalefactors.
%
% SPM.xX    - Structure containing design matrix information
%       - Required fields are:
%         xX.X      - Design matrix (raw, not temporally smoothed)
%         xX.Xnames - cellstr of parameter names corresponding to columns
%                     of design matrix
%       - Optional fields are:
%         xX.K      - Sparse temporal smoothing matrix (see spm_sptop)
% 		    - Or cell of session-specific structures (see spm_filter)
%                   - Design & data are smoothed using K
%                     (model is K*Y = K*X*beta + K*e)
%                   - Note that K should not smooth across block boundaries
%                   - defaults to speye(size(xX.X,1))
%         xX.xVi    - structure describing intrinsic temporal auto-correlation
%                   - required fields are
%                     xX.xVi.Vi - intrinsic temporal auto-correlation matrix
%                               - defaults to speye(size(xX.X,1))
%
% SPM.xM    - Structure containing masking information, or a simple column vector
%         of thresholds corresponding to the images in VY.
%       - If a structure, the required fields are:
%         xM.TH - nVar x nScan matrix of analysis thresholds, one per image
%         xM.I  - Implicit masking (0=>none, 1=>implicit zero/NaN mask)
%         xM.VM - struct array of mapped explicit mask image volumes
% 		- (empty if no explicit masks)
%               - Explicit mask images are >0 for valid voxels to assess.
%               - Mask images can have any orientation, voxel size or data
%                 type. They are interpolated using nearest neighbour
%                 interpolation to the voxel locations of the data Y.
%       - Note that voxels with constant data (i.e. the same value across
%         scans) are also automatically masked out.
%
% SPM.F_iX0 - Indicies of design matrix columns to form the reduced design
%         matrix. The ensuing F-test (implemented through F-contrasts)
%         is labelled "effects of interest", and is to filter the saved
%         data pointlist (Y.mad).
%       - If F_iX0 is a structure array
%	  F_iX0.iX0  - indices as above
%	  F_iX0.name - name of F-contrast
%       - See Christensen for details of F-contrasts
%
%_______________________________________________________________________
%
% spm_spm is the heart of the SPM package. Given image files and a
% General Linear Model, it estimates the model parameters, residual
% variance, and smoothness of the standardised residual fields, writing
% these out to disk in the current working directory for later
% interrogation in the results section. (NB: Existing analyses in the
% current working directory are overwritten.)
%
% The model is expressed via the design matrix (xX.X). The basic model
% at each voxel is of the form is Y = X*beta * e, for data Y, design
% matrix X, (unknown) parameters B, and residual errors e. The errors
% are assummed to be independent and identically Normally distributed
% with zero mean and unspecified variance. The parameters are estimated
% by ordinary least squares, using matrix methods, and the residual
% variance estimated.
%
% Note that only a single variance component is considered. This is
% *always* a fixed effects model. Random effects models can be effected
% using summary statistics, summarising the data such that the fixed
% effects in the model on the summary data are those effects of
% interest (i.e. the population effects). In this case the residual
% variance for the model on the summary data contains the appropriate
% variance components in the appropriate ratio. See spm_RandFX.man for
% further details.
%
% Under the additional assumption that the standardised residual images
% are strictly stationary standard Gaussian random fields, results from
% Random field theory can be applied to estimate the significance
% statistic images (SPM's) accounting for the multiplicity of testing
% at all voxels in the volume of interest simultaneously. The required
% parameters are the volume, and Lambda, the variance covariance matrix
% of partial derivatives of the standardised error fields. The
% algorithm estimates the variances of the partial derivatives in the
% axis directions (the diagonal of Lambda). The covariances (off
% diagonal elements of Lambda) are assumed zero.
% 
%                           ----------------
%
% For temporally correlated (fMRI) data, the algorithm implements the
% technique of Worsley & Friston (1995). In this approach the model is
% assummed to fit such that the residuals have (slight) short-term
% (intrinsic) autocorrelation given by Vi. (I.e. Residuals e =
% sqrt(Vi)*e', where e' is an (unobserved) white noise time series).
% The data and model are then temporally filtered prior to model
% fitting by a linear filter given by matrix K, giving model K*Y =
% K*X*beta + K*e. K=inv(sqrt(Vi)) corresponds to pre-whitening (leaving
% residuals e'), K=I to no temporal smoothing (appropriate for
% independent data when Vi=I), and K=S (a temporal filter matrix - see
% spm_make_filter) for band-pass filtering.
% 
% The autocorrelation in the filtered time series is then K*Vi*K'
% Standard results for serially correlated regression can then be used
% to produce variance estimates and effective degrees of freedom
% corrected for the temporal auto-correlation. Note that these
% corrections give non-integer degrees of freedom.
% 
% Vi can be passed as a parameter. If Vi is not specified then it is
% taken as I. Often Vi is unknown (or spatially variant, or just
% difficult to estimate). Provided the intrinsic autocorrelation Vi is
% small relative to that imposed by temporal smoothing (i.e. the
% temporal smoothing swamps the intrinsic autocorrelation), the
% variance-covariance structure of the residuals is approximately that
% imposed by the smoothing, i.e K*Ve*K' ~ K*Vi*K' (Ve = estimated Vi).
% if xX.xVi.row{n} is specified Vi is estimated using an AR(1) model
% for each session (n). 
% 
% The volume analsed is the intersection of the threshold masks,
% explicit masks and implicit masks. See spm_spm_ui for further details
% on masking options.
%
%                           ----------------
%
% MV:
% If the response variable is multivariate (i.e. size(VY,2) > 1) then
% spm_spm proceeds with a voxel by voxel ManCova to produce a SPM{F}
% based on Wilks Lambda for all effects of interest (specified by F_iX0).
% The ensuing parameter estimates, data (Y.mad) and residual sum of squares
% pertain to the first canonical variate. This is the linear combination
% of response variables that maximizes the sum of squares explained
% by the effects of interest relative to error.  Because there is only
% one contrast (F_iX0) the SPM{F} is created at this point and details
% are saved in xCon.
% 
%-----------------------------------------------------------------------
%
% The output of spm_spm takes the form of an SPM.mat file of analysis
% parameters, and 'float' Analyze images of the parameter and variance
% estimates. An 8bit zero-one mask image indicating the volume assessed
% is also written out, with zero indicating voxels outside tha analysed
% volume.
%
%                           ----------------
%
% SPM.mat                                         - analysis parameters
% The SPM.mat file contains the following variables:
%     SPMid     - string identifying SPM & program version
%     VY        - as input
%
%     xX        - design matrix structure
%               - all the fields of the input xX are retained
%               - the following additional fields are added:
%     xX.V      - V matrix (xX.K*xX.xVi.Vi*xX.K')
%     xX.xKXs   - space structure for K*X (xX.K*xX.X), the temporally smoothed
%                 design matrix
%               - given as spm_sp('Set',xX.K*xX.X) - see spm_sp for details
%                 (so xX.xKXs.X is K*X)
%     xX.pKX    - pseudoinverse of K*X (xX.K*xX.X), computed by spm_sp
%                 (this was called PH in spm_AnCova)
%     xX.pKXV   - pinv(K*X)*V  (this was called PHV in spm_AnCova)
%     xX.Bcov   - pinv(K*X)*V*pinv(K*X)' - variance-covariance matrix
%                 of parameter estimates (when multiplied by ResMS)
%                 (NB: BCOV in SPM96 was xX.Bcov/xX.trRV, so that BCOV    )
%                 (multiplied by ResSS was the variance-covariance matrix )
%                 (of the parameter estimates. (ResSS/xX.trRV = ResMS)    )
%     xX.trRV   - trace of R*V, computed efficiently by spm_SpUtil
%     xX.trRVRV - trace of RVRV (this was called trRV2 in spm_AnCova)
%     xX.erdf   - effective residual degrees of freedom (trRV^2/trRVRV)
%     xX.nKX    - design matrix (xX.xKXs.X) scaled for display
%                 (see spm_DesMtx('sca',... for details)
% 
%     xM        - as input (but always in the structure format)
%
%     M         - 4x4 voxel->mm transformation matrix
%     DIM       - image dimensions {voxels} - column vector
%     Vbeta     - cellstr of beta image filenames (relative)
%     VResMS    - relative filename of ResMS image
%     XYZ       - 3xS (S below) vector of in-mask voxel coordinates
%     F_iX0     - structure array of default F-contrasts
%     F_iX0.iX0 - as input
%     F_iX0.name- as input
%     S         - Lebesgue measure or volume (in voxels)
%
% ...plus any additional arguments passed to spm_spm for saving in the
%    SPM.mat file
%
%                           ----------------
%
% xCon.mat                                        - contrast definitions
% The xCon.mat file contains a single structure defining the default F-contrast
% (The results section can be used to define additional contrasts.)
%     xCon       - Contrast structure (created by spm_FcUtil.m)
%     xCon.name  - Name of contrast
%     xCon.STAT  - 'F', 'T' or 'X' - for F/T-contrast ('X' for multivariate)
%     xCon.c     - (F) Contrast weights
%     xCon.X0    - Reduced design matrix (spans design space under Ho)
%                  It is in the form of a matrix (spm99b) or the
%                  coordinates of this matrix in the orthogonal basis
%                  of xX.X defined in spm_sp. 
%     xCon.iX0   - Indicates how contrast was specified:
%                  If by columns for reduced design matrix then iX0 contains the
%                  column indices. Otherwise, it's a string containing the
%                  spm_FcUtil 'Set' action: Usuall one of {'c','c+','X0'}
%                  (Usually this is the input argument F_iX0.)
%     xCon.X1o   - Remaining design space (orthogonal to X0).
%                  It is in the form of a matrix (spm99b) or the
%                  coordinates of this matrix in the orthogonal basis
%                  of xX.X defined in spm_sp.
%     xCon.eidf  - Effective interest degrees of freedom (numerator df)
%     xCon.Vcon  - ...for handle of contrast/ESS image (empty at this stage)
%     xCon.Vspm  - ...for handle of SPM image (empty at this stage)
%
%                           ----------------
%
% mask.{img,hdr}                                   - analysis mask image
% 8-bit (uint8) image of zero-s & one's indicating which voxels were
% included in the analysis. This mask image is the intersection of the
% explicit, implicit and threshold masks specified in the xM argument.
% The XYZ matrix contains the voxel coordinates of all voxels in the
% analysis mask. The mask image is included for reference, but is not
% explicitly used by the results section.
%
%                           ----------------
%
% beta_????.{img,hdr}                                 - parameter images
% These are 16-bit (float) images of the parameter estimates. The image
% files are numbered according to the corresponding column of the
% design matrix. Voxels outside the analysis mask (mask.img) are given
% value NaN.
%
%                           ----------------
%
% ResMS.{img,hdr}                    - estimated residual variance image
% This is a 32-bit (double) image of the residual variance estimate.
% Voxels outside the analysis mask are given value NaN.
%
%-----------------------------------------------------------------------
%
% References:
%
% Christensen R (1996) Plane Answers to Complex Questions
%       Springer Verlag
%
% Friston KJ, Holmes AP, Worsley KJ, Poline JP, Frith CD, Frackowiak RSJ (1995)
% ``Statistical Parametric Maps in Functional Imaging:
%   A General Linear Approach''
%       Human Brain Mapping 2:189-210
%
% Worsley KJ, Friston KJ (1995)
% ``Analysis of fMRI Time-Series Revisited --- Again''
%       Neuroimage 2:173-181
%
%-----------------------------------------------------------------------
%
% For those interested, the analysis proceeds a "plank" at a time,
% where a "plank" is a bunch of lines (parallel to the x-axis) within a
% plane. The plank width is determined at run-time as the maximum
% possible (at most the plane width) plank width satisfying the memory
% constraint parameterised in the code in variable maxMem. maxMem can
% be tweaked for your system by editing the code.
%
%_______________________________________________________________________
% @(#)spm_spm.m	2.37 Andrew Holmes, Jean-Baptiste Poline, Karl Friston 99/11/26
%
% $Id: pr_estimate.m,v 1.1 2004/11/18 18:36:32 matthewbrett Exp $

%-Condition arguments
%-----------------------------------------------------------------------
if nargin < 1
  error('Need SPM design structure');
end
if nargin < 2
  if ~isfield(SPM, 'VY')
    error('Need data to estimate for');
  end
  VY = SPM.VY;
end
if ~isfield(SPM, 'xX'), error('Need design in SPM structure'); end
xX = SPM.xX;
if ~isfield(SPM, 'xM')
  xM = zeros(size(xX.X,1),1);
else
  xM = SPM.xM;
end
if ~isfield(SPM, 'F_iX0')
  F_iX0 = []; 
else
  F_iX0 = SPM.F_iX0;
end

% Check images are wt'ed
wvobj = phiw_wvimg(VY(1), struct('no_proc', 1));
if isempty(wvobj), error('Images do not appear to have been WTed'), end
wti = wtinfo(wvobj);
wtp = wti.wtprefix;
phiw_mat_name = [wtp 'phiw_spm.mat'];

%-Say hello
%-----------------------------------------------------------------------
SPMid    = spm('FnBanner',mfilename, ...
	       mars_cvs_version(mfilename, 'phido_99'));

Finter   = spm('FigName','Stats: estimation...'); spm('Pointer','Watch')

%-Parameters
%-----------------------------------------------------------------------
maxMem   = 2^30;	%-Max data chunking size, in bytes

%-Check required fields of xX structure exist - default optional fields
%-----------------------------------------------------------------------
for tmp = {'X','Xnames'}
	if ~isfield(xX,tmp)
     		error(sprintf('xX doesn''t contain ''%s'' field',tmp{:}))
	end
end
if ~isfield(xX,'K')
	xX.K  = speye(size(xX.X,1));
end
if ~isfield(xX,'xVi')
	xX.xVi = struct(	'Vi',	speye(size(xX.X,1)),...
				'Form',	'none'); 
end

%-If xM is not a structure then assumme it's a vector of thresholds
%-----------------------------------------------------------------------
if ~isstruct(xM), xM = struct(	'T',	[],...
				'TH',	xM,...
				'I',	0,...
				'VM',	{[]},...
				'xs',	struct('Masking','analysis threshold'));
end

%-Delete files from previous analyses
%-----------------------------------------------------------------------
if exist(fullfile('.',phiw_mat_name),'file')==2
	spm('alert!',{...
		'Current directory contains some phiwave stats results files!',...
    		['        (pwd = ',pwd,')'],...
		'Existing results are being overwritten!'},...
		mfilename,1);
	warning(sprintf('Overwriting existing results\n\t (pwd = %s) ',pwd))
	drawnow
end

files = { 'mask.???','ResMS.???',...
	  'beta_????.???','con_????.???',...
	  'ess_????.???', 'spm?_????.???'};
for i=1:length(files), files{i} = [wtp files{i}]; end
files{end+1} = phiw_mat_name;

for i=1:length(files)
	if any(files{i} == '*'|files{i} == '?' )
		[tmp,null] = spm_list_files(pwd,files{i});
		for i=1:size(tmp,1)
			spm_unlink(deblank(tmp(i,:)))
		end
	else
		spm_unlink(files{i})
	end
end

%-Check & note Y images dimensions, orientation & voxel size
%-----------------------------------------------------------------------
if any(any(diff(cat(1,VY(:).dim),1,1),1) & [1,1,1,0]) 
	error('images do not all have the same dimensions')
end
if any(any(any(diff(cat(3,VY(:).mat),1,3),3)))
	error('images do not all have same orientation & voxel size')
end

M      = VY(1,1).mat;
DIM    = VY(1,1).dim(1:3)';
N      = 3 - sum(DIM == 1);


%=======================================================================
% - A N A L Y S I S   P R E L I M I N A R I E S
%=======================================================================

%-Initialise design space
%=======================================================================
fprintf('%-40s: %30s','Initialising design space','...computing')    %-#

%-Construct design parmameters, and store in design structure xX
% Take care to apply temporal convolution - KX stored as xX.xKX.X
%-Note that Vi may not be known exactly at this point, if it is to be
% estimated. Parameters dependent on Vi are committed to xX at the end.
%-Note that the default F-contrast (used to identify "interesting" voxels
% to save raw data for) computation requires Vi. Thus, if Vi is to be
% estimated, any F-threshold will only be have upper tail probability UFp. 
%-----------------------------------------------------------------------
% V            - Autocorrelation matrix K*Vi*K'
% xX.xKXs      - Design space structure of KX
% xX.pKX       - Pseudoinverse of KX
% trRV,trRVRV  - Variance expectations
% erdf         - Effective residual d.f.
%-----------------------------------------------------------------------
[nScan nBeta] = size(xX.X);
[nScan nVar]  = size(VY);
KVi           = mardo_99('spm_filter', 'apply',xX.K, xX.xVi.Vi);
V             = mardo_99('spm_filter', 'apply',xX.K,KVi');
xX.xKXs       = spm_sp('Set',mardo_99('spm_filter', 'apply',xX.K, xX.X));
xX.pKX        = spm_sp('x-',xX.xKXs);
[trRV trRVRV] = spm_SpUtil('trRV',xX.xKXs,V);
erdf          = trRV^2/trRVRV;


%-Check estimability
%-----------------------------------------------------------------------
if  erdf < 0
    error(sprintf('This design is completely unestimable! (df=%-.2g)',erdf))
elseif erdf == 0
    error('This design has no residuals! (df=0)')
elseif erdf < 4
    warning(sprintf('Very low degrees of freedom (df=%-.2g)',erdf))
end


%-Default F-contrasts (in contrast structure) & Y.mad pointlist filtering
%=======================================================================
fprintf('%s%30s',sprintf('\b')*ones(1,30),'...F-contrast')           %-#

if isempty(F_iX0)
	F_iX0 = struct(	'iX0',		[],...
			'name',		'all effects');
elseif ~isstruct(F_iX0)
	F_iX0 = struct(	'iX0',		F_iX0,...
			'name',		'effects of interest');
end

%-Create Contrast structure array
%-----------------------------------------------------------------------
xCon  = spm_FcUtil('Set',F_iX0(1).name,'F','iX0',F_iX0(1).iX0,xX.xKXs);
for i = 2:length(F_iX0)
	xcon = spm_FcUtil('Set',F_iX0(i).name,'F','iX0',F_iX0(i).iX0,xX.xKXs);
	xCon = [xCon xcon];
end

%-Parameters for saving in Y.mad (based on first F-contrast)
%-----------------------------------------------------------------------
[trMV trMVMV] = spm_SpUtil('trMV',spm_FcUtil('X1o',xCon(1),xX.xKXs),V);
eidf          = trMV^2/trMVMV;
h             = spm_FcUtil('Hsqr',xCon(1),xX.xKXs);

%-Modify structures for multivariate inference
%-----------------------------------------------------------------------
if nVar > 1

	fprintf('%s%30s',sprintf('\b')*ones(1,30),'...multivariate prep')%-#

	% pseudoinverse of null partition KX0
	%---------------------------------------------------------------
	KX0         = spm_FcUtil('X0',xCon(1),xX.xKXs);
	pKX0        = pinv(KX0);

	%-Modify Contrast structure for multivariate inference
	%---------------------------------------------------------------
	str       = 'Canonical variate';
	xCon      = spm_FcUtil('Set',str,'F','iX0',xCon.iX0,xX.xKXs);

	%-Degrees of freedom (Rao 1951)
	%---------------------------------------------------------------
	h         = rank(spm_FcUtil('X1o',xCon(1),xX.xKXs));
	p         = nVar;
	r         = erdf;
	a         = r - (p - h + 1)/2;
	if (p + h) == 3;
		b = 1;
	else
		b = sqrt((p^2 * h^2 - 4)/(p^2 + h^2 - 5));
	end
	c         = (p*h - 2)/2;
	erdf      = a*b - c;
	eidf      = p*h;
	xCon.eidf = eidf;
end

fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#


%-Initialise output images
%=======================================================================
fprintf('%-40s: %30s','Output images','...initialising')             %-#

%-Image dimensions
%-----------------------------------------------------------------------
xdim    = DIM(1); ydim = DIM(2); zdim = DIM(3);
YNaNrep = spm_type(VY(1,1).dim(4),'nanrep');

%-Intialise the name of the new mask : current mask & conditions on voxels
%-----------------------------------------------------------------------
VM    = struct(		'fname',	[wtp 'mask.img'],...
			'dim',		[DIM',spm_type('uint8')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	'phiwave:resultant analysis mask');
VM    = spm_create_image(VM);


%-Intialise beta image files
%-----------------------------------------------------------------------
Vbeta_tmp = deal(struct(...
			'fname',	[],...
			'dim',		[DIM',spm_type('float')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	''));
for i = 1:nBeta
	Vbeta_tmp.fname   = sprintf('%sbeta_%04d.img', wtp, i);
	Vbeta_tmp.descrip = sprintf('phiwave:beta (%04d) - %s',i,xX.Xnames{i});
	spm_unlink(Vbeta_tmp.fname)
	Vbeta(i)         = spm_create_image(Vbeta_tmp);
end


%-Intialise residual sum of squares image file
%-----------------------------------------------------------------------
VResMS = struct(	'fname',	[wtp 'ResMS.img'],...
			'dim',		[DIM',spm_type('double')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	'phiwave:Residual sum-of-squares');
VResMS = spm_create_image(VResMS);


%-Intialise residual sum of squares image file
%-----------------------------------------------------------------------
if nVar > 1
	Vspm   = struct('fname',	[wtp 'mvSPMF.img'],...
			'dim',		[DIM',spm_type('double')],...
			'mat',		M,...
			'pinfo',	[1 0 0]',...
			'descrip',	'phiwave:multivariate F');
	Vspm   = spm_create_image(Vspm);
end

fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...initialised')        %-#


%=======================================================================
% - F I T   M O D E L   &   W R I T E   P A R A M E T E R    I M A G E S
%=======================================================================

%-Find a suitable block size for the main loop, which proceeds a bunch
% of lines at a time (minimum = one line; maximum = one plane)
% (maxMem is the maximum amount of data that will be processed at a time)
%-----------------------------------------------------------------------
blksz	= maxMem/8/nScan/nVar;			%-block size (in bytes)
if ydim < 2, error('ydim < 2'), end		%-need at least 2 lines
nl 	= max(min(round(blksz/xdim),ydim),1); 	%-max # lines / block
clines	= 1:nl:ydim;				%-bunch start line #'s
blines  = diff([clines ydim+1]);		%-#lines per bunch
nbch    = length(clines);			%-#bunches


%-Intialise other variables used through the loop 
%=======================================================================
BePm	    = zeros(1,xdim*ydim);		    %-below plane (mask)
CrVox       = struct('res',[],'ofs',[],'ind',[]);   %-current voxels
						    % res : residuals
   						    % ofs : mask offset
						    % ind : indices

xords  = [1:xdim]'*ones(1,ydim); xords = xords(:)'; %-plane X coordinates
yords  = ones(xdim,1)*[1:ydim];  yords = yords(:)'; %-plane Y coordinates

%-Initialise XYZ matrix of in-mask voxel co-ordinates (real space)
%-----------------------------------------------------------------------
XYZ   = [];

%-Smoothness estimation variables
%-----------------------------------------------------------------------
S      = 0;                                     % Volume analyzed (in voxels)

%-parameter for estimation of intrinsic correlations AR(1) model
%-----------------------------------------------------------------------
A      = 0;					%-regression coeficient	

%-Cycle over bunches of lines within planes (planks) to avoid memory problems
%=======================================================================
spm_progress_bar('Init',100,'model estimation','');

for z = 1:zdim				%-loop over planes (2D or 3D data)

    zords   = z*ones(xdim*ydim,1)';	%-plane Z coordinates
    CrBl    = [];			%-current plane betas
    CrmvF   = [];			%-current plane mvF-squared
    CrResSS = [];			%-current plane ResSS

    for bch = 1:nbch			%-loop over bunches of lines (planks)

	%-# Print progress information in command window
	%---------------------------------------------------------------
	fprintf('\r%-40s: %30s',sprintf('Plane %3d/%-3d, plank %3d/%-3d',...
		z,zdim,bch,nbch),' ')                                %-#

	cl    = clines(bch); 	 	%-line index of first line of bunch
	bl    = blines(bch);  		%-number of lines for this bunch

	%-construct list of voxels in this bunch of lines
	%---------------------------------------------------------------
	I     = ((cl-1)*xdim+1):((cl+bl-1)*xdim);	%-lines cl:cl+bl-1
	xyz   = [xords(I); yords(I); zords(I)];		%-voxel coords in bch


	%-Get data & construct analysis mask for this bunch of lines
	%===============================================================
	fprintf('%s%30s',sprintf('\b')*ones(1,30),'...read & mask data')%-#
	CrLm    = logical(ones(1,xdim*bl));		%-current lines mask
	CrLmxyz = zeros(size(CrLm));			%-and for smoothnes

	%-Compute explicit mask
	% (note that these may not have same orientations)
	%---------------------------------------------------------------
	for i = 1:length(xM.VM)
		tM   = inv(xM.VM(i).mat)*M;		%-Reorientation matrix
		tmp  = tM * [xyz;ones(1,size(xyz,2))];	%-Coords in mask image

		%-Load mask image within current mask & update mask
		%-------------------------------------------------------
		CrLm(CrLm) = spm_sample_vol(xM.VM(i),...
				tmp(1,CrLm),tmp(2,CrLm),tmp(3,CrLm),0) > 0;
	end
	
	%-Get the data in mask, compute threshold & implicit masks
	%---------------------------------------------------------------
	Y     = zeros(nScan,xdim*bl);
	for i = 1:nScan
		if ~any(CrLm), break, end		%-Break if empty mask
		Y(i,CrLm)  = spm_sample_vol(VY(i,1),... %-Load data in mask
				xyz(1,CrLm),xyz(2,CrLm),xyz(3,CrLm),0);
		CrLm(CrLm) = Y(i,CrLm) > xM.TH(i,1);	%-Threshold (& NaN) mask
		if xM.I & ~YNaNrep & xM.TH(i,1)<0	%-Use implicit 0 mask
			CrLm(CrLm) = abs(Y(i,CrLm))>eps;
		end
	end

	%-Mask out voxels where data is constant
	%---------------------------------------------------------------
	CrLm(CrLm) = any(diff(Y(:,CrLm),1));

	%-Apply mask
	%---------------------------------------------------------------
	Y          = Y(:,CrLm);			%-Data matrix within mask
	CrS        = sum(CrLm);			%-#current voxels
	CrVox.ofs  = I(1) - 1;			%-Current voxels line offset
	CrVox.ind  = find(CrLm);		%-Voxel indicies (within bunch)


	%-if any voxels
	%---------------------------------------------------------------
	nVox  = sum(CrLm);
	if nVox

	%-Proceed with General Linear Model & smoothness estimation
	%===============================================================
	if nVar == 1				% univariate

		%-Estimate intrinsic correlation structure AR(1) model
		%-------------------------------------------------------
		switch xX.xVi.Form

		    case 'AR(1)'
		    %---------------------------------------------------
		    fprintf('%s%30s',sprintf('\b')*ones(1,30),...
					'...AR(1) estimation')	     %-#

		    for i = 1:length(xX.xVi.row)
			y = spm_detrend(Y(xX.xVi.row{i},:));
			q = 1:(size(y,1) - 1);
			a = sum(y(q,:).*y(q + 1,:))./sum(y(q,:).*y(q,:));
			A = A + [1; -mean(a)];
		    end
		end

		%-Temporal smoothing
		%-------------------------------------------------------
		fprintf('%s%30s',sprintf('\b')*ones(1,30),...
					'...temporal smoothing')     %-#

		KY        = mardo_99('spm_filter', 'apply',xX.K, Y);

		%-General linear model: least squares estimation
		% (Using pinv to allow for non-unique designs            )
		% (Including temporal convolution of design matrix with K)
		%-------------------------------------------------------
		fprintf('%s%30s',sprintf('\b')*ones(1,30),...
					'...parameter estimation')   %-#
		beta      = xX.pKX * KY;		%-Parameter estimates
		res       = spm_sp('r',xX.xKXs,KY);	%-Residuals
		ResSS     = sum(res.^2);		%-Res sun-of-squares
		clear KY				%-Clear to save memory

	%-ManCova (assuming no filtering)
	%===============================================================
	else
		
		%-get nVar-variate response variable
		%-------------------------------------------------------
		fprintf('%s%30s',sprintf('\b')*ones(1,30),...
				  '...Canonical Variates Analysis')   %-#

		y     = zeros(nScan,nVar,nVox);
		Y     = zeros(nScan,nVox);
		res   = zeros(nScan,nVox);
		beta  = zeros(nBeta,nVox);
		V     = zeros(nVar,nVox);
		for i = 1:nScan
			for j = 1:nVar
				y(i,j,:)  = spm_sample_vol(VY(i,j),...
				xyz(1,CrLm),xyz(2,CrLm),xyz(3,CrLm),0);
			end
		end
		for i = 1:nVox
			
			%-parameter estimates
			%-----------------------------------------------
			y(:,:,i)  = y(:,:,i) - KX0*(pKX0 * y(:,:,i));
			BETA      = xX.pKX * y(:,:,i);
			h         = xX.xKXs.X * BETA;
			r         = y(:,:,i) - h;

			%-Canonical variate analysis
			%-----------------------------------------------
			[u v]     = eig(h'*h,r'*r);
			v         = diag(v);
			CU        = u(:,find(v == max(v)));
			
			%-project onto first CV
			%-----------------------------------------------
			V(:,i)    = v;
			res(:,i)  = r*CU;
			Y(:,i)    = y(:,:,i)*CU;
			beta(:,i) = BETA*CU;

		end

		% conpute multivariate F transform for Wilk's Lambda
		%-------------------------------------------------------
		ResSS = sum(res.^2);		%-along canonical vector
		W     = prod(1./(1 + V)).^(1/b);
		mvF   = (1 - W)./W*erdf/eidf;
		CrmvF = [CrmvF,mvF];

	end

	clear Y					%-Clear to save memory


	%-Save betas etc. for current plane in memory as we go along
	% (if there is not enough memory, could save directly as float)
	% (analyze images, or *.mad and retreive when plane complete )
	%---------------------------------------------------------------
	CrBl 	= [CrBl,beta];
	CrResSS = [CrResSS,ResSS];
	
	end % (nVox)

	%-Append new inmask voxel locations and volumes
	%---------------------------------------------------------------
	XYZ            = [XYZ,xyz(:,CrLm)];	%-InMask XYZ voxel coordinates
	S              = S + CrS;		%-Volume analysed (voxels)
	    					% (equals size(XYZ,2))

	%-Roll... 
	%---------------------------------------------------------------
	BePm(I)        = CrLm;			%-"below plane" mask

    end % (for bch = 1:nbch)


    %-Plane complete, write out plane data to image files
    %===================================================================
    fprintf('%s%30s',sprintf('\b')*ones(1,30),'...saving plane')     %-#

    %-Mask image
    %-BePm now contains a complete plane mask
    %-------------------------------------------------------------------
    VM    = spm_write_plane(VM, reshape(BePm,xdim,ydim), z);

    %-Construct voxel indices for BePm
    %-------------------------------------------------------------------
    Q     = find(BePm);
    tmp   = NaN*ones(xdim,ydim);

    %-Write beta images
    %-------------------------------------------------------------------
    for i = 1:nBeta
        if length(Q), tmp(Q) = CrBl(i,:); end
	Vbeta(i) = spm_write_plane(Vbeta(i),tmp,z);
    end

    %-Write ResSS into ResMS (variance) image
    % (Scaling of ResSS to ResMS by trRV is accomplished by adjusting the
    % (scalefactor at the end, once the intrinsic temporal autocorrelation
    % (Vi has been estimated.
    %-------------------------------------------------------------------
    if length(Q), tmp(Q) = CrResSS; end
    VResMS = spm_write_plane(VResMS,tmp,z);		

    %-Write SPM (multivariate inference only)
    %-------------------------------------------------------------------
    if nVar > 1
	if length(Q), tmp(Q) = CrmvF; end
	Vspm = spm_write_plane(Vspm,tmp,z);	
    end

    %-Report progress
    %-------------------------------------------------------------------
    fprintf('%s%30s',sprintf('\b')*ones(1,30),'...done')             %-#
    spm_progress_bar('Set',100*(bch + nbch*(z-1))/(nbch*zdim));

end % (for z = 1:zdim)
fprintf('\n')                                                        %-#


%=======================================================================
% - P O S T   E S T I M A T I O N   C L E A N U P
%=======================================================================
if S == 0, warning('No inmask voxels - empty analysis!'), end


%-Intrinsic autocorrelations: Vi
%=======================================================================
fprintf('%-40s: %30s','Design parameters','...intrinsic autocorrelation') %-#

%-Compute (session specific) intrinsic autocorrelation Vi
%-----------------------------------------------------------------------
switch xX.xVi.Form
	case 'AR(1)'
	%---------------------------------------------------
	p     = length(A) - 1;			% order AR(p)
	A     = A/A(1);
	for i = 1:length(xX.xVi.row)
		q     = xX.xVi.row{i};
		n     = length(q);
		Ki    = inv(spdiags(ones(n,1)*A',-[0:p],n,n));
		Ki    = Ki.*(Ki > 1e-6);
		Vi    = Ki*Ki';
		D     = spdiags(sqrt(1./diag(Vi)),0,n,n);
		Vi    = D*Vi*D;
		xX.xVi.Vi(q,q) = Vi;
	end
end
xX.xVi.Param = A;


%-[Re]-enter Vi & derived values into design structure xX
%-----------------------------------------------------------------------
fprintf('%s%30s',sprintf('\b')*ones(1,30),'...V, & traces')          %-#

KVi      = mardo_99('spm_filter', 'apply',xX.K, xX.xVi.Vi);
xX.V     = mardo_99('spm_filter', 'apply',xX.K,KVi'); 	%-V matrix
xX.pKXV  = xX.pKX*xX.V;				%-for contrast variance weight
xX.Bcov  = xX.pKXV*xX.pKX';			%-Variance of est. param.
[xX.trRV,xX.trRVRV] ...				%-Variance expectations
         = spm_SpUtil('trRV',xX.xKXs,xX.V);
xX.erdf  = xX.trRV^2/xX.trRVRV;			%-Effective residual d.f.

%-Compute scaled design matrix for display purposes
%-----------------------------------------------------------------------
fprintf('%s%30s',sprintf('\b')*ones(1,30),'...scaling DesMtx')       %-#
xX.nKX   = spm_DesMtx('sca',xX.xKXs.X,xX.Xnames);

%-Set VResMS scalefactor as 1/trRV (raw voxel data is ResSS)
%-----------------------------------------------------------------------
VResMS.pinfo(1) = 1/xX.trRV;


%-"close" written image files, updating scalefactor information
%=======================================================================
fprintf('%s%30s',sprintf('\b')*ones(1,30),'...closing image files')  %-#
VM                      = spm_create_image(VM);
for i=1:nBeta, Vbeta(i) = spm_create_image(Vbeta(i)); end
if nVar > 1,   Vspm     = spm_create_image(Vspm);     end
VResMS                  = spm_create_image(VResMS);

%-Unmap files, retaining image names, and reset erdf if MV
%-----------------------------------------------------------------------
fprintf('%s%30s',sprintf('\b')*ones(1,30),'...tidying file handles') %-#
VM     = VM.fname;
Vbeta  = {Vbeta.fname}';
VResMS = VResMS.fname;
if nVar > 1
	xCon.Vspm = Vspm.fname;
	xX.erdf   = erdf;
end

fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#



%-Save remaining results files and analysis parameters
%=======================================================================
fprintf('%-40s: %30s','Saving results','...writing')                 %-#

%-Save analysis parameters in phiw_spm.mat file
%-----------------------------------------------------------------------
SPM = mars_struct('ffillmerge', SPM, ...
		  struct(...
		      'SPMid', SPMid, ...
		      'VY',    {VY}, ...
		      'xX',    xX, ...
		      'xM',    xM, ...
		      'M',     M, ...
		      'DIM',   DIM, ...
		      'VM',    VM, ...
		      'Vbeta', {Vbeta}, ...
		      'VResMS',VResMS, ...
		      'XYZ',   XYZ, ...
		      'F_iX0', F_iX0, ...
		      'S',     S, ...
		      'xPhi',  struct('estimated', 1, 'wave', thin(wvobj)), ...
		      'swd',   pwd, ...
		      'xCon',  xCon));

% save design
savestruct(phiw_mat_name, SPM);

fprintf('%s%30s\n',sprintf('\b')*ones(1,30),'...done')               %-#

%=======================================================================
%- E N D: Cleanup GUI
%=======================================================================
spm_progress_bar('Clear')
spm('FigName','Stats: done',Finter); spm('Pointer','Arrow')
fprintf('%-40s: %30s\n','Completed',spm('time'))                     %-#
fprintf('...use the results section for assessment\n\n')             %-#