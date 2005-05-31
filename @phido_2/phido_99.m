function o = phido_99(o)
% convert phido_2 object to phido_99 object
% 
% $Id: phido_99.m,v 1.1 2005/05/31 11:10:12 matthewbrett Exp $
  
des_o = mardo_99(o.mardo_2);
o = phido(des_o);
