/* 

do first scale inverse wavelet transform in x dimension of matrix 
FORMAT t = do_iwtx(t, h, g, dlp, dhp, reco_detail)
See the do_iwtx.m file for detail

$Id: do_iwtx.c,v 1.4 2004/07/10 05:01:28 matthewbrett Exp $ 

*/ 

#include "mex.h"

/* Input arguments */
#define	M	prhs[0]
#define	RH	prhs[1]
#define	RG	prhs[2]
#define DLP     prhs[3]
#define DHP     prhs[4]
#define RECO_D  prhs[5]

/* output argument */
#define IWM     plhs[0]

/* indices for filters */
#define HI      0
#define GI      1
#define N       2

/* max min ceil floor minifunctions */
int max0(int a, int b) { /* returns max of a,b,0 */
  a = a > b ? a : b;
  return a > 0 ? a : 0;
}
int ceil2(int a) {
  int c;
  c = a & 1;
  return (a > 0 ? a/2 + c : a/2);
}
int floor2(int a) {
  int c;
  c = a & 1;
  return (a > 0 ? a/2: a/2 - c);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double	*m, *iwm, *f_ptr, *buf, *iwm_out_ptr;
  double        *m_ptr, *iwm_ptr, *col_ptr, *in_ptr, *out_ptr, *f[N], *pos, *f_pos;
  double        *dat_start[N], *dat_end[N], *st_ptr, *end_ptr, *lp_f;
  double        val, res1, res2;
  int           d[N], f_len_f_12[N], c_len_f_12[N], odd_f[N], odd_d[N], st_d[N], end_d[N];
  int           st_wrap[N], len_mid, odd_delay, len_x_12_m, n_cols, col;
  int           reco_detail, fno, lp_f_len_f_12, lp_c_len_f_12, lp_odd_f, lp_st_d; 
  int		lp_end_d, lp_st_wrap, len_x, len_x_12, len_f[N], len_buf, i, j;
  long int      size_m;
  
  if (nrhs < 5) 
    mexErrMsgTxt("Need at least matrix, two filters, two delays.");
  if (nlhs > 1)
    mexErrMsgTxt("Only one output returned.");
  if (mxIsComplex(M))
    mexErrMsgTxt("Cannot wt complex matrix.");
  if (mxGetClassID(M) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Input matrix should be of class double");
  if (nrhs > 5)
    reco_detail = ((int)*(mxGetPr(RECO_D))!=0);
  else reco_detail = 1;

  /* Assign pointers to the parameters */
  m          = mxGetPr(M);
  f[HI]      = mxGetPr(RH);
  f[GI]      = mxGetPr(RG);

  /* get delays */
  d[HI]       = (int)*(mxGetPr(DLP));
  d[GI]       = (int)*(mxGetPr(DHP));

  /* get dimensions and lengths*/
  len_x    = mxGetM(M);
  n_cols   = mxGetN(M);
  size_m   = len_x * n_cols;
  len_f[HI] = mxGetM(RH) * mxGetN(RH);
  len_f[GI] = mxGetM(RG) * mxGetN(RG);

  /* check to-be-transformed length divisible by 2 */
  if (len_x & 1)
    mexErrMsgTxt("Length of x dimension must be divisible by 2.");    
  len_x_12 = len_x/2;

  /* do delay etc calculations to save time later in main loop */
  for (fno=0; fno<N; fno++) {
    /* filter length divided by 2 */
    c_len_f_12[fno] = ceil2(len_f[fno]);
    f_len_f_12[fno] = floor2(len_f[fno]);
    odd_f[fno]      = len_f[fno] & 1;

    /* delays */
    odd_d[fno]      = d[fno] & 1;
    st_d[fno]       = floor2(d[fno]);    /* delay offset at start */
    end_d[fno]      = ceil2(d[fno]);     /* delay offset at end   */ 
    st_wrap[fno]    = max0((c_len_f_12[fno] - st_d[fno] - 1), 0);
  }

  /* make output matrix */
  IWM = mxCreateNumericArray(mxGetNumberOfDimensions(M),
			    mxGetDimensions(M), 
			    mxDOUBLE_CLASS, mxREAL);
  iwm = mxGetPr(IWM);
  m_ptr = m; 
  iwm_ptr = iwm;
  for (i=0; i<size_m; i++)
    *(iwm_ptr++) = *(m_ptr++);

  /* make buffer to contain whole row sample, wraparounds gap between
  the high and low pass bits must be as long as low-pass delay but we
  can use the low pass memory to contain the start wrap for high pass  */
  len_mid     = max0(end_d[HI], st_wrap[GI] - (st_wrap[HI] + len_x_12));
  len_buf     = st_wrap[HI]  + len_x_12 + len_mid + len_x_12 + max0(end_d[GI], 0);
  buf = (double *)mxCalloc(len_buf, sizeof(double));
  dat_start[HI] = buf + st_wrap[HI];
  dat_end[HI]   = dat_start[HI] + len_x_12 - 1;
  dat_start[GI] = dat_end[HI] + 1 + len_mid;
  dat_end[GI]   = dat_start[GI] + len_x_12 - 1;
  
  /* for each x column */
  col_ptr = iwm;
  for (col=0; col < n_cols; col++) {
    /* copy the row data to buffer */
    out_ptr = dat_start[HI];
    in_ptr  = col_ptr;
    for (i=0; i<len_x_12; i++)
      *(out_ptr++) = *(in_ptr++);
    if (reco_detail) {
      out_ptr = dat_start[GI];
      for (i=0; i<len_x_12; i++)
	*(out_ptr++) = *(in_ptr++);
    }

    /* for each of the low pass and high pass filters, if required */
    for (fno=0; fno<= reco_detail; fno++) {
      iwm_out_ptr = col_ptr;

      /* loop variables for speed - probably overkill */
      lp_f_len_f_12 = f_len_f_12[fno];
      lp_c_len_f_12 = c_len_f_12[fno];
      lp_odd_f  = odd_f[fno];
      lp_st_d   = st_d[fno];
      lp_end_d  = end_d[fno];
      lp_st_wrap = st_wrap[fno];
      odd_delay = odd_d[fno];
      lp_f      = f[fno];
      len_x_12_m = len_x_12 - odd_delay;

      /* make end wrap */
      st_ptr  = dat_start[fno];
      end_ptr = dat_end[fno];
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
	for (j=0; j<lp_f_len_f_12; j++) {
	  res2 += *(f_pos--) * *(++f_ptr);
	  f_ptr++;
	}
	if (fno) *(iwm_out_ptr++) += res2;
	else     *(iwm_out_ptr++) = res2;
      }

      /* move along row */
      for (i=0; i<len_x_12_m; i++) { /* taking into account odd_delay */
	f_ptr = lp_f;
	f_pos = pos++;
	res1 = 0;
	res2 = 0;
	/* move back along filter */
	for (j=0; j<lp_f_len_f_12; j++) {
	  val = *f_pos--;
	  res1 += val * *(f_ptr++);  /* odd portion of filter */
	  res2 += val * *(f_ptr++);  /* even portion */
	}
	if (lp_odd_f)
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
      if (odd_delay) {
	/* move back along odd part of filter */
	f_ptr = lp_f;
	f_pos = pos;
	res1 = 0;
	for (j=0; j<lp_c_len_f_12; j++) {
	  res1 += *(f_pos--) * *(f_ptr++);
	  f_ptr++;
	}
	if (fno) *(iwm_out_ptr++) += res1;
	else     *(iwm_out_ptr++) = res1;
      } /* end conv */
      
    } /* for each filter */

    /* move to next row */
    col_ptr += len_x; 
    
  } /* for each row */
  
  /* free memory */
  mxFree(buf);

}
