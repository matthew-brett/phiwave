/*
        pplot_elbow.c

	Point-Change analysis
	Reference:
	Stephens MA, "Tests for the Uniform Distribution", 
	In Goodness-of-Fit Techniques (D'Agostino RB, Stephens MA Eds.)
	NewYork, Marcel Dekker, pp.331-366, 1986
*/

#include <math.h>
#include "mex.h"

/* Input Output Arguments */
#define	PVALS	prhs[0]
#define	BRKVAL	plhs[0]

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double		*pptr, plen, m, c, cplus, cpluscor;
    double 		i,j;
    int                 donef;

    if ((nrhs != 1) || (nlhs > 1))
		mexErrMsgTxt("Inappropriate usage.");

    /* Assign pointers to the parameters */
    pptr    = mxGetPr(PVALS);
    plen    = mxGetM(PVALS) * mxGetN(PVALS);

    donef = 0;
    i = plen;
    while (!donef) {
      m = sqrt(i);
      m = m + 0.2 + 0.68/m;
      c = 0.4/i*m;
      donef = 1;
      for (j=1;j<=i;j++) {
	cplus = pptr[(int)(j-1)]-j/(i+1);
	cpluscor = cplus*m+c;
	if (cpluscor >= 1.073) {
	  donef = 0;
	  i--;
	  break;
	}
      }
      if (i < 3) {
	i = 3;
	donef = 1;
      }
    }

    BRKVAL = mxCreateDoubleMatrix(1, 1, mxREAL);
    *(mxGetPr(BRKVAL)) = i;
}
