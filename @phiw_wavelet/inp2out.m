function [odim, oimgi] = inp2out(w, idim)
% inp2out - return output dimensions and indices for input vol
% given input dimensions idim
%
% $Id: inp2out.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

odim = outdim(w, idim);
oimgi = floor((odim-idim)/2)+1;
oimgi(2,:) = oimgi(1,:)+idim-1;