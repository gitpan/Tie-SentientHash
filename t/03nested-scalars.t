#!/usr/bin/perl -w
#
# $Id: 03nested-scalars.t,v 1.4 2001/01/26 15:59:43 andrew Exp $
#
# Test nested scalars
#
# These tests are INCOMPLETE.

use strict;
use Test;
use vars qw($commit_called $sh $scalar $aref $href $sref $modified $was_unmodified $newval @arr);

use Data::Dumper; 	# I need this to try and work out what's going on

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => 6;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}


# Test that the module loads OK

use Tie::SentientHash;


$scalar = 42;

$href = { X => 1, Y => 2, Z => 3};
$aref = [ qw(a b c d e f)];
$sref = \$scalar;


$sh = new Tie::SentientHash
                  { TRACK_CHANGES => 1,
		    COMMIT_SUB    => \&my_commit },
                  { SREF => \$sref,
		    AREF => \$aref,
		    HREF => \$href };

ok ($sh->isa('Tie::SentientHash'));
$modified = $sh->_modified;

ok(ref $sh->{SREF}     eq 'SCALAR' &&
   ref ${$sh->{SREF}}  eq 'SCALAR' &&
   $${$sh->{SREF}}     == $scalar);

ok(ref $sh->{AREF}     eq 'SCALAR' &&
   ref ${$sh->{AREF}}  eq 'ARRAY' &&
   ${$sh->{AREF}}->[0] eq 'a');

ok(ref $sh->{HREF}     eq 'SCALAR' &&
   ref ${$sh->{HREF}}  eq 'HASH' &&
   ${$sh->{HREF}}->{X} == 1);


# Test modification of scalar

$was_unmodified = !$modified->{SREF};
eval { $${$sh->{SREF}} = $newval = 43; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{SREF} &&
   ref $sh->{SREF}    eq 'REF' &&
   ref ${$sh->{SREF}} eq 'SCALAR' &&
   $${$sh->{SREF}}    == $newval);

undef $sh;
ok($commit_called);



sub my_commit {
    $commit_called = 1;
}

exit(0);
