function [o, others] = phido(params,passf)
% phido - class constructor for MarsBaR design object
% inputs [defaults]
% params  - structure, either:
%             containing SPM design or mardo object or 
%             containing fields for phido object, which should include
%             'des_struct', containing design structure, or 'mardo'
%             containing mardo design structure.
% passf   - if 1, or not passed, will try children objects to see if
%           they would like to own this design
%
% outputs
% o       - phido object
% others  - any unrecognized fields from params, for processing by
%           children
%
% phido is pronounced like Fido, the dog's name.
% 
% phido is a container for mardo designs - see the mardo constructor
% functions for details.  The container allows us to use the various
% methods for SPM designs contained in the mardo classes; among other
% advantages, this makes compatibility with different versions of SPM
% more-or-less seamless.  Meanwhile, we can overload the estimation and
% other routines to do phiwave processing.
% 
% This constructor first converts any inputs that are not mardo designs, to
% mardo designs.  It then labels itself as a phido design, inheriting from
% the mardo object, and passes itself to candidate phido design classes (99
% and 2 type designs) for these classes to further claim the object.  If the
% (99 or 2) classes claim the object, they return an object of class (99 or
% 2), which inherits the phido class just created in this call to the
% object.
% 
% Note the "passf" input flag; this is a trick to allow the other phido
% classes (99 and 2) to create a phido object for them to inherit,
% without this constructor passing the phido object back to the other
% classes, creating an infinite loop.  So, it is by default set to 1, and
% the newly created phido object is passed to the other phido classes for
% them to claim ownership.  The other phido classes can call this
% constructor with passf set to 0 in order for the constructor merely to
% make a phido object, without passing back to the other classes. 
% 
% $Id: phido.m,v 1.1 2004/09/14 05:16:00 matthewbrett Exp $
