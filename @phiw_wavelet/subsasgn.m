function result = subsasgn(this, Struct, rhs)
%SUBSASGN  Method to over load . notation in assignments.
%   Publicize subscripted assignments to private fields of object.
%
% $Id: subsasgn.m,v 1.1.1.1 2004/06/25 15:20:43 matthewbrett Exp $

result = builtin('subsasgn', this, Struct, rhs );