#!/usr/bin/perl -w
#
# $Id: 05readonly.t,v 1.1 1999/06/18 10:54:52 andrew Exp $
#
# Test READONLY, FORBID_INSERTS, FORBID_DELETES, FORBID_CHANGES attributes.


use strict;
use Test;
use vars qw($commit_called $href $before $modified $was_unmodified $newval);

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => 23;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}

use Tie::SentientHash;
use Data::Dumper;

# Test READONLY attributes

$href = new Tie::SentientHash
                  { TRACK_CHANGES => 1,
		    READONLY      => [ qw(W X Y Z) ],
		    COMMIT_SUB    => \&my_commit },
                  { U => 13,
		    W => 42,
		    X => [ 1, 2, 3],
		    Y => { A => 1,
			   B => 2,
			   C => 3 },
		    Z => { Z2 => { Z3 => { Z4 => 'in a maze of twisty passages all alike' } } } };


ok ($href->isa('Tie::SentientHash'));

$modified = $href->_modified;

# Modify a non-readonly element

$was_unmodified = !$modified->{U};
eval { $href->{U} = $newval = 42; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{U} &&
   $href->{U} == $newval);


# Delete a non-readonly element

delete $modified->{U};
$was_unmodified = !$modified->{U} && exists $href->{U};
eval { delete $href->{U} };
ok(!$@ &&
   $was_unmodified &&
   $modified->{U} &&
   ! exists $href->{U});



# Insert a new element

$was_unmodified = !$modified->{V} && !exists $href->{V};
eval { $href->{V} = $newval = 42; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{V} &&
   $href->{V} == $newval);


# Delete the inserted element

delete $modified->{V};
$was_unmodified = !$modified->{V} && exists $href->{V};
eval { delete $href->{V} };
ok(!$@ &&
   $was_unmodified &&
   $modified->{V} &&
   ! exists $href->{V});


# Try to modify a scalar element

$before = Dumper($href);
eval { $href->{W} = 1; };
ok($@ && !$modified->{W} && $href->{W} == 42 && Dumper($href) eq $before);

# Try to modify an element of an array element

$before = Dumper($href);
eval { $href->{X}->[1] = 13; };
ok($@ && !$modified->{X} && $href->{X}->[1] == 2 && Dumper($href) eq $before);

# Try to modify an element of a hash element

$before = Dumper($href);
eval { $href->{Y}->{A} = 2; };
ok($@ && !$modified->{Y} && $href->{Y}->{A} == 1 && Dumper($href) eq $before);

# Try to add an element to a hash element

$before = Dumper($href);
eval { $href->{Y}->{D} = 13; };
ok($@ && !$modified->{Y} && !exists $href->{Y}->{D} && Dumper($href) eq $before);

# Try to modify an element of a deeply nested hash element

$before = Dumper($href);
eval { $href->{Z}->{Z2}->{Z3}->{Z4} = 13; };
ok($@ && !$modified->{Z} && Dumper($href) eq $before);


# Add a new top level element -- this should be allowed

$before = Dumper($href);
eval { $href->{A} = 42; };
ok(!$@ && $modified->{A} && $href->{A} == 42 && Dumper($href) ne $before);

undef($href);
ok($commit_called);
undef($commit_called);


# Now the same again but with FORBID_CHANGES set


$href = new Tie::SentientHash
                  { TRACK_CHANGES  => 1,
		    FORBID_CHANGES => 1,
		    READONLY       => [ qw (X Y) ], # FORBID_CHANGES takes precedence
		    COMMIT_SUB     => \&my_commit },
                  { W => 42,
		    X => [ 1, 2, 3],
		    Y => { A => 1,
			   B => 2,
			   C => 3 },
		    Z => { Z2 => { Z3 => { Z4 => 'in a maze of twisty passages all alike' } } } };

ok ($href->isa('Tie::SentientHash'));

$modified = $href->_modified;

# Try to modify a scalar element

$before = Dumper($href);
eval { $href->{W} = 1; };
ok($@ && !$modified->{W} && $href->{W} == 42 && Dumper($href) eq $before);

# Try to modify an element of an array element

$before = Dumper($href);
eval { $href->{X}->[1] = 13; };
ok($@ && !$modified->{X} && $href->{X}->[1] == 2 && Dumper($href) eq $before);

# Try to modify an element of a hash element

$before = Dumper($href);
eval { $href->{Y}->{A} = 2; };
ok($@ && !$modified->{Y} && $href->{Y}->{A} == 1 && Dumper($href) eq $before);

# Try to add an element to a hash element

$before = Dumper($href);
eval { $href->{Y}->{D} = 13; };
ok($@ && !$modified->{Y} && !exists $href->{Y}->{D} && Dumper($href) eq $before);

# Try to modify an element of a deeply nested hash element

$before = Dumper($href);
eval { $href->{Z}->{Z2}->{Z3}->{Z4} = 13; };
ok($@ && !$modified->{Z} && Dumper($href) eq $before);


# Add a new top level element -- this should NOT be allowed 

$before = Dumper($href);
eval { $href->{A} = 42; };
ok($@ && !$modified->{A} && !exists $href->{A}  && Dumper($href) eq $before);

undef($href);
ok(!defined $commit_called);


# Test out FORBID_DELETES

$href = new Tie::SentientHash
                  { TRACK_CHANGES => 1,
		    FORBID_DELETES => 1,
		    READONLY      => [ qw(W X Y Z) ],
		    COMMIT_SUB    => \&my_commit },
                  { U => 13,
		    W => 42,
		    X => [ 1, 2, 3],
		    Y => { A => 1,
			   B => 2,
			   C => 3 },
		    Z => { Z2 => { Z3 => { Z4 => 'in a maze of twisty passages all alike' } } } };


ok ($href->isa('Tie::SentientHash'));

$modified = $href->_modified;

# Try to delete a non-readonly element

$was_unmodified = !$modified->{U} && exists $href->{U};
$before = Dumper($href);
eval { delete $href->{U} };
ok($@ &&
   $was_unmodified &&
   !$modified->{U} &&
   Dumper($href) eq $before);


# Try to delete a read-only element

$was_unmodified = !$modified->{W} && exists $href->{W};
$before = Dumper($href);
eval { delete $href->{W} };
ok($@ &&
   $was_unmodified &&
   !$modified->{W} &&
   Dumper($href) eq $before);





exit(0);

sub my_commit {
    $commit_called++;
}


exit(0);

