# Tie::SentientHash -- 'intelligent' hashes that track changes, etc
#
# $Id: SentientHash.pm,v 1.7 2001/01/26 11:12:16 andrew Exp $
# Copyright (C) 1999-2001, Andrew Ford and Ford & Mason Ltd.  
# All rights reserved
# This module is free software. It may be used, redistributed
# and/or modified under the terms of the Perl Artistic License

package Tie::SentientHash;
$VERSION = 0.54;


=head1 NAME

Tie::SentientHash - Perl module implementing intelligent objects

=head1 SYNOPSIS

  use Tie::SentientHash;

  tie %hash, 'Tie::SentientHash', $meta_data, $initial_data;

  $hashref    = Tie::SentientHash->new($meta_data, $initial_data);
  $modified   = $hashref->modified($key [, $bool])
  $untiedhash = $hashref->export;
  $metadata   = $hashref->_metadata;
  $modified   = $hashref->_modified;

  $hashref->{key} = 'value';
  $hashref->{key1}{key2} = $value;
  $value2 = $hashref->{key};
  undef $hashref;


=head1 DESCRIPTION

The C<Tie::SentientHash> package provides intelligent objects.  The
objects are represented as hashes which:

=over

=item * 

provide read-only elements

=item *

provide 'special' elements that are handled by user-supplied functions

=item *

disallow changes to the data as specified by metadata

=item *

track changes and call a 'commit changes' function when the object is
destroyed

=back

References to scalars, arrays, hashes and objects can be stored in
hash elements in which case the referenced object is tied to an
internal class of the appropriate type (Tie::SentientHash::NestedHash,
::NestedArray or ::NestedScalar), so that changes to the nested data
structures can be tracked.

The constructor is invoked with two hash references: the first
contains metadata and the second the initial data values.  The
metadata hash may contain the following flags:

=over 4

=item READONLY

a list of hash entries that are read-only (read-only elements cannot
be modified -- except by special element handlers -- or deleted and
are not deleted when the CLEAR method is called)

=item SPECIAL

a hash of name/subroutine-refs pairs that specifies elements that are
handled specially (special elements also cannot be deleted).  The user
function is called both for STORE (with four arguments) and for FETCH
(with three arguments).  The arguments are: a reference to the
metadata hash, a reference to the data hash, the element key and if
the funtion is being called for a STORE operation, the value to be
stored.  SPECIAL elements can be used to implement calculated
attributes.

=item TRACK_CHANGES 

flag to indicate that the class should keep track of the keys of
modified (top-level) hash elements

=item COMMIT_SUB

a reference to a subroutine to commit changes (called with a reference
to the data hash and a reference to the metadata hash)

=item FORBID_INSERTS

forbid inserts into hash and sub-hashes/arrays

=item FORBID_DELETES

forbid deletes from hash

=item FORBID_CHANGES

forbid any changes

=back

Trying to change an object in a way that is forbidden by the metadata
will cause the module to croak.

Changes are only tracked at the top level.


The API is as follows:

=over 4

=item tie %hash, 'Tie::SentientHash', $meta_data, $initial_data

Functional interface to create a new sentient hash.  $meta_data
describes the properties of the sentient hash (as outlined above) and
$initial_data is the initial content of the sentient hash.


=item Tie::SentientHash->new($meta_data, $initial_data)

Object oriented constructor for a sentient hash.


=item $hashref->modified([$key [, $bool]])

If called with no arguments in a scalar returns an indication of
whether the sentient hash has been modified.  If called with no
arguments in an array context returns the list of elements that have
been modified.  Otherwise queries or sets the modification status of a
specific top level element.

=item $untiedhash = $hashref->export

Creates an "untied" copy of the sentient hash.

=back

If a commit function is specified when the sentient hash is created it
will be called when the destructor is called (normall when it is
garbage-collected).


=head1 EXAMPLE

I use Tie::SentientHash as the basis for implementing persistent
objects in my CGI/mod_perl scripts.  The details of reading and
writing the objects from and to the database is handled by a class,
but neither the class nor the high level code needs to keep track of
whether the object has been changed in any way.

For example if you had a pay per view system of some kind you could
have a script that contained the following fragment:

   sub pay_per_view ($$) {
     my($cust_id, $cost) = @_;

     my $cust = load Customer $cust_id;
     $cust->{CREDIT} -= $cost;
   }

The customer object would be implemented in a module sketched out
below.  A commit function is specified on the call to create a new
sentient object, and that function will be called when $cust goes out
of scope at the end of the pay_per_view function and can write the
modified object back to the database.  If none of the attributes had
been modified then the commit function would not be invoked.

   package Customer;

   sub load ($$) {
     my ($class, $cust_id) = @_;
     my $data = {};

     # read customer data from a database into $data

     my $meta = { COMMIT_SUB     => \&_commit,
                  READONLY       => [ qw( CUST_ID ) ],
                  FORBID_INSERTS => 1 };

     return bless Tie::SentientHash->new($meta, $data), $class;
   }

   sub _commit ($$) {
     my ($meta, $data) = @_;

     # As we have been called, something has changed.  The names of
     # the modified fields are the keys of $meta->{MODIFIED}.  We had
     # better write the data back out to the database.
 
   }


=head1 RESTRICTIONS

Full array semantics are only supported for Perl version 5.005.

Starting with version 0.54 blessed objects may be stored in the
I<sentient hash>, however this functionality is experimental, has not
been exhaustively tested, may not work, and may be subject to change.
Use at your own peril!

Tie::SentientHash ties nested elements to internal subclasses so it
can track changes.  If you keep references to such elements and modify
them directly then Tie::SentientHash may not be aware of the changes.

Objects of classes that use the tie mechanism may not work when stored
in a sentient hash.

If you use an object as the data for a new sentient hash, then the
hash will not be re-blessed, i.e. if $object is an object then after

    $href = Tie::SentientHash->new($meta, $object);

$href will be blessed in the same class as $object.  This means you
cannot use the C<modified> or C<export> methods on $href.  However you
can use them on the tied array, e.g.:

    @keys    = (tied %$href)->modified;
    $newhash = (tied %$href)->export;

As Tie::Sentient recursively ties nested elements to internal
subclasses it may not be very efficent on large, deeply nested data
structures.  (If I find the time I may provide a C implementation that
would be faster in this regard).


=head1 AUTHOR

Andrew Ford <A.Ford@ford-mason.co.uk>

Please let me know if you use this module.


=head1 SEE ALSO

perl(1).

=head1 COPYRIGHT

Copyright 1999-2001 Andrew Ford and Ford & Mason Ltd. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



#

use strict;
use vars qw($VERSION @ISA);
use Carp;


# The SentientHash objects are stored as a blessed four-element array.
# The array indexes for the blessed array are as follows:

use constant DATA     => 0;	# holds a reference to the data hash
use constant META     => 1;     # holds a reference to the metadata hash
use constant RO       => 2;	# holds a reference to the read-only map
use constant WATCH_FN => 3;	# holds a reference to the watch
                                # function for the object

my $pkg    = __PACKAGE__;
my $nested = $pkg . '::Nested';
my %builtin = ( map { $_ => 1 } qw( ARRAY HASH REF SCALAR ) );


# Object oriented constructor
# usage: $x = Tie::SentientHash->new($metaref, $dataref)

sub new ($$$) {
    my($class, $meta, $data) = @_;
    my $this = {};
    if (my $dataclass = ref $data) {
	$class = $dataclass unless $builtin{$dataclass};
    }
    tie %$this, $pkg, $meta, $data or croak 'cannot create tied hash';
    return bless $this, ref $class || $class;
}


# Tie constructor
# usage tie %hash, 'Tie::SentientHash', $metaref, $dataref

sub TIEHASH ($$;$) {
    my($class, $meta, $data) = @_;
    croak 'no metadata specified' unless ref $meta;
    $data ||=  {};

    # Enable change tracking if a commit subroutine is specified, but
    # disable if changes are forbidden.  Make the MODIFIED metadata
    # element a reference to an empty hash reference.  The tracker sub
    # is a reference to a closure that references the MODIFIED element
    # unless tracking is disabled in which case it is a reference to a
    # dummy routine.

    $meta->{TRACK_CHANGES} = 1 if ref $meta->{COMMIT_SUB} eq 'CODE';
    my $forbid_changes = $meta->{FORBID_CHANGES};
    my $track_changes  = $meta->{TRACK_CHANGES} && !$forbid_changes;
    my $modified       = $meta->{MODIFIED} = {};
    my $watch_fn       = $track_changes ? sub { $modified->{$_[0]} = 1; } : sub {};
    my $readonly_map   = { map { $_, 1 } @{$meta->{READONLY}} };


    # Need to recursively tie elements that are themselves references

    while (my($key, $val) = each %$data) {
	next unless ref $val;
	my $readonly = $forbid_changes || $readonly_map->{$key};
	$data->{$key} = _tie_ref($val, $readonly, $readonly ? sub {} : $watch_fn, $key);
    }

    return bless [ $data, $meta, $readonly_map, $watch_fn ], $class;
}


# Private function to tie a reference to a nested element

sub _tie_ref ($$$$) {
    my($val, $readonly, $track_sub, $key) = @_;
    my($newval, $package, $class);

    if (UNIVERSAL::isa($val, 'HASH')) {
	$package = __PACKAGE__ . '::NestedHASH';
	$class   = ref $val unless ref $val eq 'HASH';
	if (tied %$val && ref tied %$val eq $package) {
	    $newval = $val;
	}
	else {
	    tie(%$newval, $package, $val, $readonly, $track_sub, $key);
	}
    }
    elsif (UNIVERSAL::isa($val, 'ARRAY')) {
	$package = __PACKAGE__ . '::NestedARRAY';
	$class   = ref $val unless ref $val eq 'ARRAY';
	if (tied @$val && ref tied %$val eq $package) {
	    $newval = $val;
	}
	else {
	    tie(@$newval,  $package, $val, $readonly, $track_sub, $key);
	}
    }
    elsif (   UNIVERSAL::isa($val, 'REF')
	   or UNIVERSAL::isa($val, 'SCALAR')) {
	$package = __PACKAGE__ . '::NestedSCALAR';
	$class   = ref $val unless ref $val eq 'REF' or ref $val eq 'SCALAR';
	if (tied $$val && ref tied %$val eq $package) {
	    $newval = $val;
	}
	else {
	    my $scalarval;
	    $newval = \$scalarval;
	    tie($$newval, $package, $$val, $readonly, $track_sub, $key);
	}
    }
    else {
	croak('only references to ARRAY, HASH, REF or SCALAR allowed');
    }
    bless $newval, $class if $class;
    return $newval;
}


sub FETCH ($$) {
    my($self, $key) = @_;
    my $meta = $self->[META];
    my $data = $self->[DATA];
    
    if (exists $meta->{'SPECIAL'}->{$key}) {
	return &{$meta->{'SPECIAL'}->{$key}}($meta, $data, $key);
    }
    else {
	return $data->{$key};
    }
}


# Store a new value in the SentientHash.
# If the new value is a reference then it needs to be recursively tied
# The function first checks that this top level element is modifiable
# so if it has to tie the value then it will ipso facto be "not
# read-only".  The tracker subroutine is picked out of the blessed
# array.

sub STORE ($$$) {
    my($self, $key, $val) = @_;
    my $meta = $self->[META];
    my $data = $self->[DATA];
    
    if (exists $meta->{'SPECIAL'}->{$key}) {
	return &{$meta->{'SPECIAL'}->{$key}}($meta, $data, $key, $val);
    }
    elsif (!exists $data->{$key} and $meta->{FORBID_INSERTS}) {
	croak("insertion of new elements not allowed");
    }
    elsif ($meta->{FORBID_CHANGES} or exists $self->[RO]->{$key}) {
	croak("attempt to modify readonly element");
    }
    else {
	my $watch_fn = $self->[WATCH_FN];
	&$watch_fn($key);
	return $data->{$key} = ref $val ? _tie_ref($val, undef, $watch_fn, $key) :  $val;
    }
}




# start key-looping
sub FIRSTKEY ($) {
    my $data  = $_[0]->[DATA];
    my $reset = scalar keys %$data;
    return each %$data;
}

# continue key-looping -- coded for performance

sub NEXTKEY ($) { return each %{ $_[0]->[DATA] }; }
sub EXISTS ($$) { return exists $_[0]->[DATA]->{$_[1]}; }

sub DELETE ($) {
    my $self = shift;
    my $meta = $self->[META];

    croak "deletion of elements is forbidden" if $meta->{'FORBID_DELETES'};

    my $data = $self->[DATA];
    my $key = shift;
    return unless exists $data->{$key};
    croak "element is read-only" if $self->[RO]->{$key} || $meta->{SPECIAL}->{$key};
    &{$self->[WATCH_FN]}($key);
    return delete $data->{$key};
}


sub CLEAR ($) {
    my $self = shift;
    croak("CLEAR operation not supported") if $self->{FORBID_DELETES};

    my $meta = $self->[META];
    my $data = $self->[DATA];
    my $ro   = $self->[RO];
    my $special = $meta->{SPECIAL};
    my $watch_fn = $self->[WATCH_FN];

    foreach my $key (keys %$data) {
	next if $ro->{$key} || $special->{$key};
	delete $data->{$key};
	&$watch_fn($key);
    }
}


# Destructor.
# Calls the user's commit function if one was specified
# and COMMIT_ON_DESTROY was specified or something was modified
# If the SentientHash was created with the new method then the DESTROY
# function will be called twice; firstly as a destructor of the object
# and secondly to untie the (anonymous) hash.  We can just return on
# the first call, which is when we are called with a reference to the
# tied hash.

sub DESTROY ($) {
    my $self = shift;
    return if tied(%$self);
    my $meta = $self->[META];
    my $data = $self->[DATA];

    # May need to recursively untie hash refs

    if (exists $meta->{COMMIT_SUB} 
	and ($meta->{COMMIT_ON_DESTROY} or keys %{$meta->{MODIFIED}})) {
	while (my($key, $val) = each %$data) {
	    next unless ref $val; 
	    if (UNIVERSAL::isa($val, 'ARRAY')) {
		$data->{$key} = tied(@$val)->_UNTIE;
	    }
	    elsif (UNIVERSAL::isa($val, 'HASH')) {
		$data->{$key} = tied(%$val)->_UNTIE;
	    }
	    elsif (   UNIVERSAL::isa($val, 'REF')
		   or UNIVERSAL::isa($val, 'SCALAR')) {
		$data->{$key} = tied($$val)->_UNTIE;		
	    }
	    else {
	    }
	}
	&{$meta->{'COMMIT_SUB'}}($meta, $data);
    }
}


# Export -- create an untie'd copy of the object
# This has not been tested.

sub export ($) {
    my $self = shift;
    my $data = $self->[DATA];
    my $export = {};

    while (my($key, $val) = each %$data) {
	my $ref = ref $val;
	if ($ref) {
	    if ($ref =~ /HASH$/) {
		$val = tied(%$val)->_export;
	    }
	    elsif ($ref =~ /ARRAY$/) {
		$val = tied(@$val)->_export;
	    }
	    else {
		$val = tied($$val)->_export;
	    }
	}
	$export->{$key} = $val;
    }
    return $export;
}


sub modified ($;$$) {
    my($self, $key, $bool) = @_;
    my $modified = $self->_modified;

    if (defined $bool) {
	my $data = $self->_data;
	if (defined $key) {
	    if ($bool) {
		$modified->{$key} = 1;
	    }
	    else {
		delete $modified->{$key};
	    }
	}
	else {
	    if ($bool) {
		map { $modified->{$_} = $bool } (keys %$data);
	    }
	    else {
		delete $modified->{keys %$modified};
	    }
	}
    }
    else {
	return (defined $key
		? exists $modified->{$key}
		: (wantarray
		   ? keys %$modified
		   : (keys %$modified) > 0));
    }
}


# Private function to access the modified hash of a SentientHash

sub _modified ($) { 
    my $self = shift;
    $self = tied(%$self) if $self->isa('HASH');
    return $self->_metadata->{MODIFIED};
}

# Private function to access the metadata hash of a SentientHash

sub _metadata ($) {
    my $self = shift;
    $self = tied(%$self) if $self->isa('HASH');
    return $self->[META];
}


# Private function to access the metadata hash of a SentientHash

sub _data ($) {
    my $self = shift;
    $self = tied(%$self) if $self->isa('HASH');
    return $self->[DATA];
}


##############################################################################
#
# Internal package for handling nested hashes
#
##############################################################################

package Tie::SentientHash::NestedHASH;

use constant    DATA     => 0;
use constant    READONLY => 1;
use constant    WATCH_FN => 2;
use constant    MODKEY   => 3;
use Carp;
    
sub TIEHASH ($$$$) {
    my($class, $data, $readonly, $watch_fn, $modkey) = @_;
    
    while (my($key, $val) = each %$data) {
	$data->{$key} = Tie::SentientHash::_tie_ref($val, $readonly, $watch_fn, $modkey) 
	  if ref $val;
    }
    bless [ $data, $readonly, $watch_fn, $modkey ], $class;
}

sub FETCH ($$)  { return $_[0]->[DATA]->{$_[1]}; }
sub STORE ($$$) {
    my($self, $key, $val) = @_;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $watch_fn = $self->[WATCH_FN];
    my $modkey   = $self->[MODKEY];
    &$watch_fn($modkey);
    return $self->[DATA]->{$key}
      = ref $val ? Tie::SentientHash::_tie_ref($val, undef, $watch_fn, $modkey) : $val;
}


# start key-looping

sub FIRSTKEY ($) {	         
    my $data = $_[0]->[DATA];
    my $reset = scalar keys %{ $data };
    each %{ $data };
}

# continue key-looping -- coded for performance
    
sub NEXTKEY ($) { return each %{ $_[0]->[DATA] }; }
sub EXISTS ($$) { return exists  $_[0]->[DATA]->{$_[1]}; }

sub CLEAR ($) {
    my $self = shift;
    croak 'attempt to delete readonly element' if $self->[READONLY];
    &{$self->[WATCH_FN]}($self->[MODKEY]);
    $self->[DATA] = {}; 
}
	   
sub DELETE ($$) {
    my $self = shift;
    croak 'attempt to delete readonly element' if $self->[READONLY];
    &{$self->[WATCH_FN]}($self->[MODKEY]);
    return delete $self->[DATA]->{$_[0]};    
}


# Empty destructor -- only need to do things here if the top level
# destructor needs to call the user's commit function -- hence the
# _UNTIE method.

sub DESTROY ($) {}
sub _UNTIE  ($) {
    my $self = shift;
    my $data = $self->[DATA];
    
    while (my($key, $val) = each %$data) {
	next unless ref $val;
	if (UNIVERSAL::isa($val, 'ARRAY')) {
	    $data->{$key} = tied(@$val)->_UNTIE;
	}
	elsif (UNIVERSAL::isa($val, 'HASH')) {
	    $data->{$key} = tied(%$val)->_UNTIE;
	}
	elsif (   UNIVERSAL::isa($val, 'REF') 
	       or UNIVERSAL::isa($val, 'SCALAR')) {
	    $data->{$key} = tied($$val)->_UNTIE;		
	}
	else {
	    carp("something funny happened while untying a nested hash");
	}
    }
    return $data;
}


sub _export ($) {
    my $self = shift;
    my $data = $self->[DATA];
    my $export = {};
    
    while (my($key, $val) = each %$data) {
	if (ref $val) {
	    if (UNIVERSAL::isa($val, 'HASH')) {
		$val = tied(%$val)->_export;
	    }
	    elsif (UNIVERSAL::isa($val, 'ARRAY')) {
		$val = tied(@$val)->_export;
	    }
	    elsif (   UNIVERSAL::isa($val, 'REF')
		   or UNIVERSAL::isa($val, 'SCALAR')) {
		$val = tied($$val)->_export;
	    }
	    else {
		carp("something funny happened while exporting a nested hash");
	    }
	}
	$export->{$key} = $val;
    }
    return $export;
}

    

##############################################################################
#
# Internal package for nested arrays
#
##############################################################################

package Tie::SentientHash::NestedARRAY;

use constant    DATA      => 0;
use constant    READONLY  => 1;
use constant    WATCH_FN  => 2;
use constant    MODKEY    => 3;
use Carp;

sub TIEARRAY ($$$$$) {
    my($class, $data, $readonly, $watch_fn, $modkey) = @_;

    foreach my $val (@$data) {
        $val = Tie::SentientHash::_tie_ref($val, $readonly, $watch_fn, $modkey) 
          if ref $val;
    }
    return bless [ $data, $readonly, $watch_fn, $modkey ], $class;
}

sub FETCH ($$)  { return $_[0]->[DATA]->[$_[1]]; }
sub STORE ($$$) {
    my($self, $ix, $val) = @_;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $watch_fn = $self->[WATCH_FN];
    my $modkey   = $self->[MODKEY];
    &$watch_fn($modkey);
    return $self->[DATA]->[$ix]
      = ref $val ? Tie::SentientHash::_tie_ref($val, undef, $watch_fn, $modkey) : $val;
}

sub FETCHSIZE ($)  { return scalar @{$_[0]->[DATA]}; }
sub STORESIZE ($$) {
    my($self, $newsize) = @_;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $oldlastelement = $#{$self->[DATA]};
    &{$self->[WATCH_FN]}($self->[MODKEY]) unless $newsize == $oldlastelement+1;
    $#{$self->[DATA]} = $newsize - 1;
}

sub POP ($) {
    my $self = shift;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    &{$self->[WATCH_FN]}($self->[MODKEY]);
    return pop @{$self->[DATA]};
}

sub PUSH ($@) {
    my $self = shift;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $data = $self->[DATA];
    if (@_) {
	my $watch_fn = $self->[WATCH_FN];
	my $modkey   = $self->[MODKEY];
	&$watch_fn($modkey);
	foreach my $val (@_) {
	    $val = Tie::SentientHash::_tie_ref($val, undef, $watch_fn, $modkey)
	      if ref $val;
	}
    }
    return push @$data, @_;
}

sub SHIFT ($) {
    my $self = shift;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    &{$self->[WATCH_FN]}($self->[MODKEY]);
    return shift @{$self->[DATA]};
}

sub UNSHIFT ($@) {
    my $self = shift;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $data = $self->[DATA];
    if (@_) {
	my $watch_fn = $self->[WATCH_FN];
	my $modkey   = $self->[MODKEY];
	&$watch_fn($modkey);
	foreach my $val (@_) {
	    $val = Tie::SentientHash::_tie_ref($val, undef, $watch_fn, $modkey)
	      if ref $val;
	}
    }
    return unshift @$data, @_;
}

sub SPLICE ($;$$@){
    my $self = shift;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $data   = $self->[DATA];
    my $offset = (@_) ? shift : 0;
    my $size   = @$data;
    $offset   += $size if ($offset < 0);
    my $length = (@_) ? shift : $size - $offset;

    # Return an empty list if there are no elements to delete and none
    # to insert.
    return () unless $length || @_;
    
    my $watch_fn = $self->[WATCH_FN];
    my $modkey   = $self->[MODKEY];
    &$watch_fn($modkey);
    foreach my $val (@_) {
	$val = Tie::SentientHash::_tie_ref($val, undef, $watch_fn, $modkey)
	  if ref $val;
    }
    return splice(@$data, $offset, $length, @_);
}

sub EXTEND ($$) {
    croak 'attempt to modify readonly element' if $_[0]->[READONLY];
}


# Empty destructor -- only need to do things here if the top level
# destructor needs to call the user's commit function -- hence the
# _UNTIE method.

sub DESTROY {}
sub _UNTIE {
    my $self = shift;
    my $data = $self->[DATA];
    
    foreach my $val (@$data) {
	next unless ref $val;
	if (UNIVERSAL::isa($val, 'ARRAY')) {
	    $val = tied(@$val)->_UNTIE;
	}
	elsif (UNIVERSAL::isa($val, 'HASH')) {
	    $val = tied(%$val)->_UNTIE;
	}
	elsif (   UNIVERSAL::isa($val, 'REF')
	       or UNIVERSAL::isa($val, 'SCALAR')) {
	    $val = tied($$val)->_UNTIE;		
	}
	else {
	    carp("something funny happened while untying a nested array");
	}
    }
    return $data;
}


# Export a nested array

sub _export {
    my $self = shift;
    my $data = $self->[DATA];
    my $export = [];
    
    foreach my $val (@$data) {
	if (!ref $val) {
	    push @$export, $val;
	}
	elsif (UNIVERSAL::isa($val, 'HASH')) {
	    push @$export, tied(%$val)->_export;
	}
	elsif (UNIVERSAL::isa($val, 'ARRAY')) {
	    push @$export, tied(@$val)->_export;
	}
	elsif (   UNIVERSAL::isa($val, 'REF')
	       or UNIVERSAL::isa($val, 'SCALAR')) {
	    push @$export, tied($$val)->_export;
	}
	else {
	    carp("something funny happened while exporting a nested array");
	}
    }
    return $export;
}


##############################################################################
#
# Internal package for nested scalars
#
##############################################################################

package Tie::SentientHash::NestedSCALAR;

use constant    DATA     => 0;
use constant    READONLY => 1;
use constant    WATCH_FN => 2;
use constant	MODKEY   => 3;
use Carp;
    
sub TIESCALAR ($$$$$) {
    my($class, $data, $readonly, $watch_fn, $modkey) = @_;
    $data = Tie::SentientHash::_tie_ref($data, $readonly, $watch_fn, $modkey) 
      if ref $data;
    return bless [ $data, $readonly, $watch_fn, $modkey ], $class;
}

sub FETCH ($)  { return $_[0]->[DATA]; }
sub STORE ($$) {
    my($self, $val) = @_;
    croak 'attempt to modify readonly element' if $self->[READONLY];
    my $watch_fn = $self->[WATCH_FN];
    my $modkey   = $self->[MODKEY];
    &$watch_fn($modkey);
    return $self->[DATA] 
      = ref $val ? Tie::SentientHash::_tie_ref($val, undef, $watch_fn, $modkey) : $val;
}


# Empty destructor -- only need to do things here if the top level
# destructor needs to call the user's commit function -- hence the
# _UNTIE method.

sub DESTROY {}

sub _UNTIE {
    my $self = shift;
    my $val  = $self->[DATA];

    if (!ref $val) {
	return $val;
    }
    elsif (UNIVERSAL::isa($val, 'ARRAY')) {
	return tied(@$val)->_UNTIE;
    }
    elsif (UNIVERSAL::isa($val, 'HASH')) {
	return tied(%$val)->_UNTIE;
    }
    elsif (   UNIVERSAL::isa($val, 'REF')
	   or UNIVERSAL::isa($val, 'SCALAR')) {
	return tied($$val)->_UNTIE;		
    }
    else {
	carp("something funny happened while untying a nested scalar");
    }
}


# Export a nested scalar

sub _export ($) {
    my $self = shift;
    my $val = $self->[DATA];

    if (!ref $val) {
	return $val;
    }
    elsif (UNIVERSAL::isa($val, 'HASH')) {
	return tied(%$val)->_export;
    }
    elsif (UNIVERSAL::isa($val, 'ARRAY')) {
	return tied(@$val)->_export;
    }
    elsif (   UNIVERSAL::isa($val, 'REF')
	   or UNIVERSAL::isa($val, 'SCALAR')) {
	return tied($$val)->_export;
    }
    else {
	carp("something funny happened while exporting a nested scalar");
    }
}


1;
__END__
