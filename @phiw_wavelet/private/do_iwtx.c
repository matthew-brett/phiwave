/* 

do first scale inverse wavelet transform in x dimension of matrix 
FORMAT t = do_iwtx(t, h, g, dlp, dhp, reco_detail)
See the do_iwtx.m file for detail

Todo
----
accept negative filter delays

$Id: do_iwtx.c,v 1.2 2004/07/09 16:34:38 matthewbrett Exp $ 

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

/* max min odd minifunctions */
int my_max(int a, int b) {
  return a > b ? a : b;
}
int my_min(int a, int b) {
  return a > b ? b : a;
}
int my_isodd(int a) {
  return (a & 1);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double	*m, *h, *g, *iwm, *f_ptr, *buf, *iwm_out_ptr, *filters[N], *delays[N];
  double        *m_ptr, *iwm_ptr, *col_ptr, *in_ptr, *out_ptr, *f, *pos, *f_pos;
  double        *d_start, *d_end, *d_start_h, *d_start_g, *d_end_h, *d_end_g;
  double        d, res1, res2;
  int           dlp, dhp, dlp_12, dhp_12, odd_dlp, odd_dhp, st_wrap, n_cols, col;
  int           st_wrap_h, st_wrap_g, len_mid, odd_delay, len_x_12_m, delay_p;
  int           reco_detail, len_h_12, len_g_12, delay, fno, odd_f, len_f, len_f_p; 
  int		len_x, len_x_12, f_lengths[N], len_buf, i, j, odd_h, odd_g;
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
  m                = mxGetPr(M);
  filters[HI]      = mxGetPr(RH);
  filters[GI]      = mxGetPr(RG);

  /* get delays */
  delays[HI]       = (int)*(mxGetPr(DLP));
  delays[GI]       = (int)*(mxGetPr(DHP));

  /* get dimensions and lengths*/
  len_x    = mxGetM(M);
  n_cols   = mxGetN(M);
  size_m   = len_x * n_cols;
  f_lengths[HI] = mxGetM(RH) * mxGetN(RH);
  f_lengths[GI] = mxGetM(RG) * mxGetN(RG);

  /* check to-be-transformed length divisible by 2 */
  if (my_isodd(len_x))
    mexErrMsgTxt("Length of x dimension must be divisible by 2.");    
  len_x_12 = len_x/2;

  /* do delay etc calculations to save time later in main loop */
  for (fno=0; fno<N, fno++) {
    delays_12[fno]   = delays[fno]/2;
    odd_dlp  = my_isodd(dlp);
    len_h_12 = len_h/2;
    odd_h    = my_isodd(len_h);
    st_wrap[fno] = my_max((len_h_12 + odd_h - dlp_12 - 1), 0); 
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

  /* make buffer to contain whole row sample, wraparounds */
  st_wrap_h = my_max((len_h_12 + odd_h - dlp_12 - 1), 0); /* start wrap size for h */
  st_wrap_g = my_max((len_g_12 + odd_g - dhp_12 - 1), 0); /* start wrap size for g */
  /* gap between the high and low pass bits must be as long as low-pass delay */
  /* but we can use the low pass bit to contain the start wrap for high pass  */
  len_mid   = my_max(dlp_12 + odd_dlp, st_wrap_g - (st_wrap_h + len_x_12));
  len_buf   = st_wrap_h + len_x_12 + len_mid + len_x_12 + dhp_12 + odd_dhp;
  buf = (double *)mxCalloc(len_buf, sizeof(double));
  d_start_h = buf + st_wrap_h;
  d_end_h   = d_start_h + len_x_12 - 1;
  d_start_g = d_end_h + 1 + len_mid;
  d_end_g   = d_start_g + len_x_12 - 1;
  
  /* for each x column */
  col_ptr = iwm;
  for (col=0; col < n_cols; col++) {
    /* copy the row data to buffer */
    out_ptr = d_start_h;
    in_ptr  = col_ptr;
    for (i=0; i<len_x_12; i++)
      *(out_ptr++) = *(in_ptr++);
    if (reco_detail) {
      out_ptr = d_start_g;
      for (i=0; i<len_x_12; i++)
	*(out_ptr++) = *(in_ptr++);
    }

    /* for each of the low pass and high pass filters, if required */
    for (fno=0; fno<= reco_detail; fno++) {
      iwm_out_ptr = col_ptr;
      
      if (fno) { /* detail scale */
	len_f  = len_g_12;
	odd_f  = odd_g;
	delay  = dhp_12;
	odd_delay = odd_dhp;
	f       = g;
	st_wrap = st_wrap_g;
	d_start = d_start_g;
	d_end   = d_end_g;
      } else {   /* low pass scale */
	len_f  = len_h_12;
	odd_f  = odd_h;
	delay  = dlp_12;
	odd_delay = odd_dlp;
	f      = h;
	st_wrap = st_wrap_h;
	d_start = d_start_h;
	d_end   = d_end_h;
      }
      len_x_12_m = len_x_12 - odd_delay;
      len_f_p = len_f + odd_f;
      delay_p = delay + odd_delay;

      /* make end wrap */
      out_ptr = d_end + 1;
      in_ptr  = d_start;
      for (i=0; i < delay_p; i++) {
	*(out_ptr++) = *(in_ptr++);
	if (in_ptr > d_end)
	  in_ptr = d_start;
      }
      /* make start wrap */
      out_ptr = d_start-1;
      in_ptr = d_end;
      for (i=0; i < st_wrap; i++) {
	*(out_ptr--) = *(in_ptr--);
	if (in_ptr < d_start)
	  in_ptr = d_end;
      }

      /* do convolution */
      pos = d_start + delay;

      /* do start conv for odd delay */
      if (odd_delay) {
      
	/* move back along even part of filter */
	f_ptr = f;
	f_pos = pos++;
	res2 = 0;
	for (j=0; j<len_f; j++) {
	  res2 += *(f_pos--) * *(++f_ptr);
	  f_ptr++;
	}
	if (fno) *(iwm_out_ptr++) += res2;
	else     *(iwm_out_ptr++) = res2;
      }

      /* move along row */
      for (i=0; i<len_x_12_m; i++) { /* taking into account odd_delay */
	f_ptr = f;
	f_pos = pos++;
	res1 = 0;
	res2 = 0;
	/* move back along filter */
	for (j=0; j<len_f; j++) {
	  d = *f_pos--;
	  res1 += d * *(f_ptr++);  /* odd portion of filter */
	  res2 += d * *(f_ptr++);  /* even portion */
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
      if (odd_delay) {
	/* move back along odd part of filter */
	f_ptr = f;
	f_pos = pos;
	res1 = 0;
	for (j=0; j<len_f_p; j++) {
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
