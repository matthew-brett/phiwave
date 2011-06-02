function result = subsasgn(this, Struct, rhs)
% SUBSASGN  Method to over load . notation in assignments.
%   Publicize subscripted assignments to private fields of object.
%
% $Id: subsasgn.m,v 1.2 2005/06/05 04:42:22 matthewbrett Exp $

result = builtin('subsasgn', this, Struct, rhs );