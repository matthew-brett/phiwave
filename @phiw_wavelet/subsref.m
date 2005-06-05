function result = subsref(this, Struct)
% SUBSREF Method to overload the . notation.
%   Publicize subscripted reference to private fields of object.
%
% $Id: subsref.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

result = builtin('subsref', this, Struct );