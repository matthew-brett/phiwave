function result = subsref(this, Struct)
%SUBSREF Method to overload the . notation.
%   Publicize subscripted reference to private fields of object.
%
% $Id: subsref.m,v 1.1 2004/06/25 15:20:43 matthewbrett Exp $

result = builtin('subsref', this, Struct );