#!/usr/bin/perl -w
#
# $Id: 02nested-hashes.t,v 1.1 1999/06/18 08:43:25 andrew Exp $
#
# Test nested hashes.


use strict;
use Test;
use vars qw($commit_called $href $modified $was_unmodified $newval $newval2);

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => 8;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}

use Tie::SentientHash;



$href = new Tie::SentientHash
                  { TRACK_CHANGES => 1,
		    COMMIT_SUB    => \&my_commit },
                  { X => 42,
		    Y => { A => 1,
			   B => 2,
			   C => 3 },
		    Z => { Z2 => { Z3 => { Z4 => 'in a maze of twisty passages all alike' } } } };


# Check that the hash ref is a sentient hash and fetch the reference to the 'modified' hash

ok ($href->isa('Tie::SentientHash'));
$modified = $href->_modified;


# Check that 'keys' is working

ok((keys %{$href->{Y}}) == 3);


# Test modification of a simple nested hash element

$was_unmodified = !$modified->{Y};
eval { $href->{Y}->{A} = $newval = 2; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Y}  && 
   $href->{Y}->{A} eq $newval);


# Test modification of a deeply nested hash element

$was_unmodified = !$modified->{Z};
$newval = 'in a maze of twisty passages all different';
eval { $href->{Z}->{Z2}->{Z3}->{Z4} = $newval; };
ok(!$@ &&
   $was_unmodified && 
   $modified->{Z}  &&
   $href->{Z}->{Z2}->{Z3}->{Z4} eq $newval);


# Test replacement of a nested hash element

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $href->{Z}->{Z2} = { A => $newval = 42 }; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z}  &&
   !exists $href->{Z}->{Z2}->{Z3}  &&
   (keys %{$href->{Z}->{Z2}}) == 1 &&
   $href->{Z}->{Z2}->{A} == $newval);


# Test insertion of a new nested hash

$was_unmodified  = !exists $href->{W} && !$modified->{W};
eval { $href->{W} = { W1 => $newval  = 42,
		      W2 => $newval2 = 43}; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{W} &&
   $href->{W}->{W1} == $newval  && 
   $href->{W}->{W2} == $newval2 &&
   (keys %{$href->{W}}) == 2);


# Test direct insertion of a new nested hash element

$was_unmodified = !$modified->{U};
eval { $href->{U}->{U2} = $newval = 'new hash element'; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{U} &&
   $href->{U}->{U2} eq $newval &&
   (keys %{$href->{U}}) == 1);


# Explicitly cause the sentient hash to be destroyed

undef($href);
ok($commit_called);



sub my_commit {
    $commit_called = 1;
}


exit(0);

