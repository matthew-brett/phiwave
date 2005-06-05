% Example phiwave batch script 

% Make sure phiwave is loaded
phiwave on

% SPM design path
spm_name = spm_get(1, 'SPM.mat', 'Select SPM design');

% Make phiwave design object
D = phido(spm_name);

% Set some options for estimation (see @phido/estimate.m)
params = struct('wavelet',  phiw_lemarie(2), ...
		'scales',   4, ...
		'wtprefix', 'wv_');

% Remove 's' prefix from image names in design, so we can work on the
% unsmoothed images (which assumes they exist)
D = prefix_images(D, 'remove', 's');

% Estimate the design, doing wavelet transform on the way
E = estimate(D, [], params);

% Add a good contrast we might be interested in, returning design and
% contrast number.  Of course this contrast will have to match the size
% of your design matrix
[E Ic] = add_contrasts(E, 'activation', 'T', [1 0 0]);

% Set some denoising options (see @phido/get_wdimg.m)
d_params = struct(...
    'thcalc', 'sure', ...
    'thapp', 'soft', ...
    'write_err', 1);

% Write new denoised images with given file name 
% (variance image prepended with 'err_')
Vcon = get_wdimg(E, Ic, d_params, 'denoised_sure');

% Interactive display, using some PhiWave defaults
phiw_display('display', 'orth', Vcon);
