/* 

do first scale wavelet transform in x dimension of matrix 
FORMAT t = do_wtx(t, h, g, dlp, dhp)
See the do_wtx.m file for detail

Todo
----

$Id: do_wtx.c,v 1.2 2004/07/09 16:34:38 matthewbrett Exp $

*/ 

#include "mex.h"

/* Input arguments */
#define	M	prhs[0]
#define	H	prhs[1]
#define	G	prhs[2]
#define DLP     prhs[3]
#define DHP     prhs[4]

/* output argument */
#define WM      plhs[0]

/* max min minifunctions */
int my_max(int a, int b) {
  return a > b ? a : b;
}
int my_min(int a, int b) {
  return a > b ? b : a;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double	*m, *h, *g, *wm, *g_ptr, *h_ptr, *buf, *h_out_ptr, *g_out_ptr;
  double        *m_ptr, *wm_ptr, *col_ptr, *in_ptr, *out_ptr,
    *d_start, *d_end, *h_pos, *g_pos, *h_f_pos, *g_f_pos;
  double        h_res, g_res;
  int           dlp, dhp, st_wrap, end_wrap, n_cols, col, h_g_same, h_bigger;
  int		len_x, len_x_12, len_h, len_g, len_buf, len_shared, len_diff, i, j;
  long int      size_m;
  
  if (nrhs != 5) 
    mexErrMsgTxt("Need matrix, two filters, two delays.");
  if (nlhs > 1)
    mexErrMsgTxt("Only one output returned.");
  if (mxIsComplex(M))
    mexErrMsgTxt("Cannot wt complex matrix.");
  if (mxGetClassID(M) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Input matrix should be of class double");

  /* Assign pointers to the parameters */
  m        = mxGetPr(M);
  h        = mxGetPr(H);
  g        = mxGetPr(G);

  /* get constants */
  dlp      = (int)*(mxGetPr(DLP));
  dhp      = (int)*(mxGetPr(DHP));

  /* get dimensions */
  len_x    = mxGetM(M);
  n_cols   = mxGetN(M);
  size_m   = len_x * n_cols;
  len_h    = mxGetM(H) * mxGetN(H);
  len_g    = mxGetM(G) * mxGetN(G);
  
  /* check length divisible by 2 */
  if (len_x & 1)
    mexErrMsgTxt("Length of x dimension must be divisible by 2.");    
  len_x_12 = len_x/2;
     
  /* make output matrix */
  WM = mxCreateNumericArray(mxGetNumberOfDimensions(M),
			    mxGetDimensions(M), 
			    mxDOUBLE_CLASS, mxREAL);
  wm = mxGetPr(WM);
  m_ptr = m; 
  wm_ptr = wm;
  for (i=0; i<size_m; i++)
    *(wm_ptr++) = *(m_ptr++);

  /* work out wraparound */
  st_wrap = my_max((len_h-dlp), (len_g-dhp))-1;
  end_wrap = my_max(dlp, dhp);
  len_buf = st_wrap + len_x + end_wrap;
  buf = (double *)mxCalloc(len_buf, sizeof(double));
  
  /* filter differences */
  len_shared = my_min(len_h, len_g);
  len_diff   = my_max(len_h, len_g) - len_shared;
  h_g_same   = (len_h == len_g);
  h_bigger   = (len_h > len_g);

  /* for each x column */
  col_ptr = wm;
  h_out_ptr = wm;
  g_out_ptr = wm+len_x_12;
  for (col=0; col < n_cols; col++) {
    /* copy column to buffer, with wrap */
    in_ptr  = col_ptr;
    d_start = buf + st_wrap;
    d_end   = d_start + len_x -1;
    out_ptr = d_start;
    for (i=0; i<len_x; i++)
      *(out_ptr++) = *(in_ptr++);
    /* end wrap */
    in_ptr = d_start;
    for (i=0; i<end_wrap; i++) {
      *(out_ptr++) = *(in_ptr++);
      if (in_ptr > d_end)
	in_ptr = d_start;
    }
    /* start wrap */
    out_ptr = d_start-1;
    in_ptr = d_end;
    for (i=0; i<st_wrap; i++) {
      *(out_ptr--) = *(in_ptr--);
      if (in_ptr < d_start)
	in_ptr = d_end;
    }

    /* do convolution */
    h_pos = d_start + dlp;
    g_pos = d_start + dhp;

    /* move along row */
    for (i=0; i<len_x; i+=2) {
      h_ptr = h;
      g_ptr = g;
      h_res = 0;
      g_res = 0;
      h_f_pos = h_pos;
      g_f_pos = g_pos;
      /* move back along filter */
      for (j=0; j<len_shared; j++) {
	h_res += *(h_f_pos--) * *(h_ptr++);
	g_res += *(g_f_pos--) * *(g_ptr++);
      }
      if (!h_g_same) {
	if (h_bigger) {
	  for (j=0; j<len_diff; j++)
	    h_res += *(h_f_pos--) * *(h_ptr++);
	} else {
	  for (j=0; j<len_diff; j++)
	    g_res += *(g_f_pos--) * *(g_ptr++);
	}
      }
      h_pos+=2;
      g_pos+=2;
      *(h_out_ptr++) = h_res;
      *(g_out_ptr++) = g_res;
    }
  
    /* move to next row */
    col_ptr += len_x; 
    h_out_ptr += len_x_12;
    g_out_ptr += len_x_12;
    
  }

  
  /* free memory */
  mxFree(buf);

}
