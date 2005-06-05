function [odim, oimgi] = inp2out(w, idim)
% return output dimensions, indices for input vol given input dimensions
%
% $Id: inp2out.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

odim = outdim(w, idim);
oimgi = floor((odim-idim)/2)+1;
oimgi(2,:) = oimgi(1,:)+idim-1;