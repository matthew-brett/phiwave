/* 

do first scale inverse wavelet transform in x dimension of matrix 
FORMAT t = do_iwtx(t, h, g, dlp, dhp, reco_detail, truncate)
See the do_iwtx.m file for detailed help

$Id: do_iwtx.c,v 1.1 2004/09/26 04:00:24 matthewbrett Exp $ 

*/ 

#include "mex.h"

/* Input arguments */
#define	M	prhs[0]
#define	RH	prhs[1]
#define	RG	prhs[2]
#define DLP     prhs[3]
#define DHP     prhs[4]
#define RECO_D  prhs[5]
#define TRUNC   prhs[6]

/* output argument */
#define IWM     plhs[0]

/* indices for filters */
#define HI      0
#define GI      1
#define N       2

/* max ceil floor minifunctions */
int max0(int a, int b) { /* returns max of a,b,0 */
  a = a > b ? a : b;
  return a > 0 ? a : 0;
}
int ceil2(int a) {
  return (a > 0 ? a/2 + (a & 1) : a/2);
}
int floor2(int a) {
  return (a > 0 ? a/2: a/2 - (a & 1));
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double	*m, *iwm, *f_ptr, *buf;
  double        *m_ptr, *iwm_out_ptr, *iwm_in_ptr, *in_col_ptr, *out_col_ptr, *in_ptr, *out_ptr;
  double        *f[N], *dat_start[N], *st_ptr, *end_ptr, *lp_f, *pos, *f_pos;
  double        val, res1, res2;
  const int     *m_dims;
  int           n_m_dims, is_row_vector, d[N], len_f[N],  st_d[N], end_d[N], st_wrap[N];
  int           reco_detail, truncate, len_mid, odd_delay, extra_res1, len_x_12_m;
  int           n_cols, col, fno, f_len_f_12, c_len_f_12, odd_f, lp_st_d; 
  int		lp_end_d, lp_st_wrap, len_x, len_x_12, len_buf, i, j;
  long int      size_m;
  
  if (nrhs < 5) 
    mexErrMsgTxt("Need at least matrix, two filters, two delays.");
  if (nlhs > 1)
    mexErrMsgTxt("Only one output returned.");
  if (mxIsComplex(M))
    mexErrMsgTxt("Cannot wt complex matrix.");
  if (mxIsSparse(M))
    mexErrMsgTxt("Cannot wt sparse matrix.");
  if (mxGetClassID(M) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Input matrix should be of class double");
  if (nrhs > 5)
    reco_detail = ((int)*(mxGetPr(RECO_D))!=0);
  else reco_detail = 1;
  if (nrhs > 6)
    truncate = ((int)*(mxGetPr(TRUNC))!=0);
  else truncate = 0;

  /* Assign pointers to the parameters */
  m          = mxGetPr(M);
  f[HI]      = mxGetPr(RH);
  f[GI]      = mxGetPr(RG);

  /* get delays */
  d[HI]      = (int)*(mxGetPr(DLP));
  d[GI]      = (int)*(mxGetPr(DHP));

  /* get dimensions and lengths*/
  len_x    = mxGetM(M);
  n_cols   = mxGetN(M);
  size_m   = len_x * n_cols;
  n_m_dims = mxGetNumberOfDimensions(M);
  is_row_vector = (len_x == 1) & (n_m_dims == 2);
  if (is_row_vector) {
    i = n_cols;
    n_cols = len_x;
    len_x = i;
  }
  len_f[HI] = mxGetM(RH) * mxGetN(RH);
  len_f[GI] = mxGetM(RG) * mxGetN(RG);

  /* check to-be-transformed length divisible by 2 */
  if (len_x & 1)
    mexErrMsgTxt("Length of x dimension must be divisible by 2.");    
  len_x_12 = len_x/2;

  /* do delay etc calculations to save time later in main loop */
  for (fno=0; fno < N; fno++) {
    /* delay offset at start; we have to round down to accomodate the first (orphan)
     value from just the even part of the filter, if the delay is odd*/
    st_d[fno]       = floor2(d[fno]);    
    /* delay offset at end.  Here we have to round up to accomodate
       the last value from the odd part of the filter, if the delay is
       odd; we don't need this last value if we are truncating though */ 
    end_d[fno]      = ceil2(d[fno] - truncate);     
    st_wrap[fno]    = max0((ceil2(len_f[fno]) - st_d[fno] - 1), 0);
  }

  /* make output matrix */
  m_dims   = mxGetDimensions(M);
  IWM = mxCreateNumericArray(n_m_dims, m_dims, mxDOUBLE_CLASS, mxREAL);
  iwm = mxGetPr(IWM);

  /* copy input into output */
  m_ptr = m; 
  iwm_out_ptr = iwm;
  for (i=0; i<size_m; i++)
    *(iwm_out_ptr++) = *(m_ptr++);

  /* make buffer to contain whole row sample, wraparounds.  The gap
     between the high and low pass segments must be as long as
     low-pass delay but we can use the low pass memory to contain the
     start wrap for the high pass segment */
  len_mid     = max0(end_d[HI], st_wrap[GI] - (st_wrap[HI] + len_x_12));
  len_buf     = st_wrap[HI]  + len_x_12 + len_mid + len_x_12 + max0(end_d[GI], 0);
  buf = (double *)mxCalloc(len_buf, sizeof(double));
  dat_start[HI] = buf + st_wrap[HI];
  dat_start[GI] = dat_start[HI] + len_x_12 + len_mid;
  
  /* for each x column */
  in_col_ptr = iwm;
  out_col_ptr = iwm;
  for (col=0; col < n_cols; col++) {
    /* copy the row data to buffer */
    out_ptr = dat_start[HI];
    in_ptr  = in_col_ptr;
    for (i=0; i<len_x_12; i++)
      *(out_ptr++) = *(in_ptr++);
    if (reco_detail) {
      out_ptr = dat_start[GI];
      for (i=0; i<len_x_12; i++)
	*(out_ptr++) = *(in_ptr++);
    }

    /* for each of the low pass and high pass filters, if required */
    for (fno=0; fno<= reco_detail; fno++) {
      iwm_in_ptr   = in_col_ptr;
      iwm_out_ptr  = out_col_ptr;

      /* loop variables for speed - probably overkill */
      lp_f      = f[fno];
      lp_st_d   = st_d[fno];
      lp_end_d  = end_d[fno];
      lp_st_wrap = st_wrap[fno];

      i = len_f[fno];
      odd_f  = i & 1;
      f_len_f_12 = i/2;
      c_len_f_12 = f_len_f_12 + odd_f;
      odd_delay  = d[fno] & 1;

      /* there is an orphan just-odd-filter pass at the end, if 
	 a) the delay is odd, we are not truncating
	 b) the delay is not odd, but we are truncating */
      extra_res1 = odd_delay ? !truncate : truncate;

      /* if there is an odd delay, or we are truncating, we do not
	 want to get _both_ odd and even filter bits from the last
	 element in the vector.

	 a) odd delay, no truncation OR even delay, truncation - we
	 only use the even part of the filter for the last value,
	 which is handled by the orphan section flagged by extra_res1

	 b) odd delay, truncation - we don't use the last value atall
      */
      len_x_12_m = len_x_12 - (odd_delay | truncate);

      /* make end wrap */
      st_ptr  = dat_start[fno];
      end_ptr = st_ptr + len_x_12 - 1;
      out_ptr = end_ptr + 1;
      in_ptr  = st_ptr;
      for (i=0; i < lp_end_d; i++) {
	*(out_ptr++) = *(in_ptr++);
	if (in_ptr > end_ptr)
	  in_ptr = st_ptr;
      }
      /* make start wrap */
      out_ptr = st_ptr-1;
      in_ptr  = end_ptr;
      for (i=0; i < lp_st_wrap; i++) {
	*(out_ptr--) = *(in_ptr--);
	if (in_ptr < st_ptr)
	  in_ptr = end_ptr;
      }

      /* do convolution */
      pos = st_ptr + lp_st_d;

      /* do start conv for odd delay */
      if (odd_delay) {      
	/* move back along even part of filter */
	f_ptr = lp_f;
	f_pos = pos++;
	res2 = 0;
	for (j=0; j < f_len_f_12; j++) {
	  res2 += *(f_pos--) * *(++f_ptr);
	  f_ptr++;
	}
	if (fno) *(iwm_out_ptr++) += res2;
	else     *(iwm_out_ptr++) = res2;
      }

      /* move along row */
      for (i=0; i < len_x_12_m; i++) { /* taking into account odd_delay */
	f_ptr = lp_f;
	f_pos = pos++;
	res1 = 0;
	res2 = 0;
	/* move back along filter */
	for (j=0; j < f_len_f_12; j++) {
	  val = *f_pos--;
	  res1 += val * *(f_ptr++);  /* odd portion of filter */
	  res2 += val * *(f_ptr++);  /* even portion */
	}
	if (odd_f)
	  res1 += *(f_pos) * *(f_ptr);
	if (fno) {
	  *(iwm_out_ptr++) += res1;
	  *(iwm_out_ptr++) += res2;
	} else {
	  *(iwm_out_ptr++) = res1;
	  *(iwm_out_ptr++) = res2;
	}
      } /* along row */
  
      /* do end conv for odd delay */
      if (extra_res1) {
	/* move back along odd part of filter */
	f_ptr = lp_f;
	f_pos = pos;
	res1 = 0;
	for (j=0; j < c_len_f_12; j++) {
	  res1 += *(f_pos--) * *(f_ptr++);
	  f_ptr++;
	}
	if (fno) *(iwm_out_ptr++) += res1;
	else     *(iwm_out_ptr++) = res1;
      } /* end conv */
      
    } /* for each filter */

    /* move to next row */
    in_col_ptr += len_x; 
    out_col_ptr += len_x; 
    if (truncate)
      out_col_ptr--;
    
  } /* for each row */
  
  /* free memory */
  mxFree(buf);

  /* make smaller matrix if truncating */
  if (truncate) {
    if (is_row_vector)
      mxSetN(IWM, --len_x);
    else
      mxSetM(IWM, --len_x);
    iwm = mxRealloc(iwm, len_x * n_cols * sizeof(double)); 
    mxSetPr(IWM, iwm);
  }
}
