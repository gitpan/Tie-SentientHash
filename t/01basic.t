#!/usr/bin/perl -w
#
# $Id: 01basic.t,v 1.4 1999/06/18 10:33:14 andrew Exp $
#
# Basic tests
# test that:
#    the module loads OK
#    a simple single level hash can be created via "tie" and via "new"

use strict;
use Test;
use vars qw($loaded);

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => 13;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}


# Test that the module loads OK

use Tie::SentientHash;
END { print "not ok 1\n" unless $loaded; }
$loaded = 1;
ok(1);


# Test the creation of a sentient hash throught the "tie" intereface

my $data1     = { X => 42, Y => 43, Z => 44 };
my $metadata1 = { TRACK_CHANGES => 1 };
my %hash1;
tie %hash1, 'Tie::SentientHash', $metadata1, $data1;
ok (tied(%hash1)->isa('Tie::SentientHash'));

my $modified = tied(%hash1)->_modified;

# Fetching elements (FETCH)

ok (int(keys %hash1) == 3 &&
    $hash1{X} == 42 && $hash1{Y} == 43 && $hash1{Z} == 44 &&
    !$modified->{X} && !$modified->{Y} && !$modified->{Z});

# Modifiying through assignment (STORE)

$hash1{Y} = 41;
ok (int(keys %hash1) == 3 && $hash1{Y} == 41 &&
    !$modified->{X} && $modified->{Y} && !$modified->{Z});

# Modifiying through autoincrement and += (FETCH and STORE)

$hash1{Z}++; $hash1{Z} += 2;
ok (int(keys %hash1) == 3 && $hash1{Z} == 47 &&
    !$modified->{X} && $modified->{Y} && $modified->{Z});

# Adding a new element

$hash1{W} = 'xyzzy';
ok (int(keys %hash1) == 4 && $hash1{W} eq 'xyzzy' &&
    $modified->{W} && !$modified->{X} && $modified->{Y} && $modified->{Z});

# Removing an element

delete $hash1{X};
ok (int(keys %hash1) == 3 && !exists $hash1{X} &&
    $modified->{W} && $modified->{X} && $modified->{Y} && $modified->{Z});




# Test a simple hash created through the "new" method

my $data2 = { A => 1, B => 2, C => 3 };
my $metadata2 = { TRACK_CHANGES => 1 };
my $href2 = new Tie::SentientHash $metadata2, $data2;
ok (ref $href2 eq 'Tie::SentientHash');

$modified = $href2->_modified;


# Fetching elements (FETCH)

ok (int(keys %$href2) == 3 &&
    $href2->{A} == 1 && $href2->{B} == 2 && $href2->{C} == 3 &&
    !$modified->{A} && !$modified->{B} && !$modified->{C});

# Modifiying through assignment (STORE)

$href2->{B} = 42;
ok (int(keys %$href2) == 3 && $href2->{B} == 42 &&
    !$modified->{A} && $modified->{B} && !$modified->{C});

# Modifiying through autodecrement and += (FETCH and STORE)

$href2->{C}--; $href2->{C} += 2;
ok (int(keys %$href2) == 3 && $href2->{C} == 4 &&
    !$modified->{A} && $modified->{B} && $modified->{C});

# Adding a new element (the undefined value this time)

$href2->{D} = undef;
ok (int(keys %$href2) == 4 && exists $href2->{D} && !defined $href2->{D} &&
    $modified->{D} && !$modified->{A} && $modified->{B} && $modified->{C});

# Removing an element

delete $href2->{A};
ok (int(keys %$href2) == 3 && !exists $href2->{A} &&
    $modified->{D} && $modified->{A} && $modified->{B} && $modified->{C});


exit(0);
