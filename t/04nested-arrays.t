#!/usr/bin/perl -w
#
# $Id: 04nested-arrays.t,v 1.3 1999/06/18 10:38:11 andrew Exp $
#
# Test nested arrays.


use strict;
use Test;
use vars qw($commit_called $href $modified $was_unmodified $newval @arr);

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => 17;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}

use Tie::SentientHash;



$href = new Tie::SentientHash
                  { TRACK_CHANGES => 1,
		    COMMIT_SUB    => \&my_commit },
                  { X => 42,
		    Y => [ 0, 1, 2, 3 ],
		    Z => [ [ qw(ALPHA BETA GAMMA ) ],
			   [ qw(ALPHA CHARLIE DELTA ECHO FOXTROT) ],
			   [ [ qw(a b c d e f) ] ],
			 ] };

ok ($href->isa('Tie::SentientHash'));
$modified = $href->_modified;


# Test access to nested array elements

ok(!$modified->{Y} &&
   ref $href->{Y}  eq 'ARRAY' &&
   $href->{Y}->[1] == 1);

ok(!$modified->{Z} &&
   ref $href->{Z}       eq 'ARRAY' &&
   ref $href->{Z}->[0]  eq 'ARRAY' &&
   $href->{Z}->[1]->[4] eq 'FOXTROT');

# Test modification of nested array elements

$was_unmodified = !$modified->{Y};
eval { $href->{Y}->[2] = $newval = 42; };
ok(!@$ &&
   $was_unmodified &&
   $modified->{Y} &&
   $href->{Y}->[2] eq $newval);

$was_unmodified = !$modified->{Z};
eval { $href->{Z}->[1]->[4] = $newval = 'ECHO echo ...'; };
ok(!@$ &&
   $was_unmodified &&
   $modified->{Z} &&
   $href->{Z}->[1]->[4] eq $newval);


# Test counting of nested array elements

ok(scalar @{$href->{Y}} == 4 &&
   scalar @{$href->{Z}} == 3 &&
   scalar @{$href->{Z}->[0]} == 3 &&
   scalar @{$href->{Z}->[1]} == 5 &&
   scalar @{$href->{Z}->[2]->[0]} == 6);


# Test the addition of new nested array elements (leaving a gap)

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $href->{Z}->[1]->[6] = $newval = 'HOTEL'; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   scalar @{$href->{Z}->[1]} == 7 &&
   $href->{Z}->[1]->[6] eq $newval &&
   !defined $href->{Z}->[1]->[5]);



# Test the addition of a new nested array

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $href->{Z}->[2]->[0]->[6] = [ 0, 1, 2, 3, $newval = 4, 5 ]; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   scalar @{$href->{Z}->[2]->[0]} == 7 &&
   ref $href->{Z}->[2]->[0]->[6]  eq 'ARRAY' &&
   $href->{Z}->[2]->[0]->[6]->[4] == $newval);


# Test extending a nested array

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $#{$href->{Z}->[2]} = $#{$href->{Z}->[2]}; };
ok(!$@ &&
   $was_unmodified &&
   !$modified->{Z});

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $#{$href->{Z}->[2]} = 10; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   $#{$href->{Z}->[2]} == 10 &&
   !defined $href->{Z}->[2]->[9]);


# Test shift

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $newval = shift @{$href->{Z}->[0]}; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   scalar @{$href->{Z}->[0]} == 2 &&
   $newval eq 'ALPHA' &&
   $href->{Z}->[0]->[0] eq 'BETA');

# Test pop

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval { $newval = pop @{$href->{Z}->[0]}; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   scalar @{$href->{Z}->[0]} == 1 &&
   $newval eq 'GAMMA' &&
   $href->{Z}->[0]->[0] eq 'BETA');

# Test unshift

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval {  unshift @{$href->{Z}->[0]}, 'ALPHA', 'OMEGA'; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   scalar @{$href->{Z}->[0]} == 3 &&
   $href->{Z}->[0]->[0] eq 'ALPHA' &&
   $href->{Z}->[0]->[1] eq 'OMEGA' &&
   $href->{Z}->[0]->[2] eq 'BETA');

# Test push

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval {  push @{$href->{Z}->[0]}, 'GAMMA', 'DELTA'; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   scalar @{$href->{Z}->[0]} == 5 &&
   $href->{Z}->[0]->[0] eq 'ALPHA' &&
   $href->{Z}->[0]->[1] eq 'OMEGA' &&
   $href->{Z}->[0]->[2] eq 'BETA'  &&
   $href->{Z}->[0]->[3] eq 'GAMMA' &&
   $href->{Z}->[0]->[4] eq 'DELTA');


# Test splice

delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval {  @arr = splice @{$href->{Z}->[0]}, 1, 1; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   @arr == 1 &&
   $arr[0] eq 'OMEGA' &&
   scalar @{$href->{Z}->[0]} == 4 &&
   $href->{Z}->[0]->[0] eq 'ALPHA' &&
   $href->{Z}->[0]->[1] eq 'BETA'  &&
   $href->{Z}->[0]->[2] eq 'GAMMA' &&
   $href->{Z}->[0]->[3] eq 'DELTA');


delete $modified->{Z};
$was_unmodified = !$modified->{Z};
eval {  @arr = splice @{$href->{Z}->[0]}, 1, 2, 'x', 'y', 'z'; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{Z} &&
   @arr == 2 &&
   $arr[0] eq 'BETA' &&
   $arr[1] eq 'GAMMA' &&
   scalar @{$href->{Z}->[0]} == 5  &&
   $href->{Z}->[0]->[0] eq 'ALPHA' &&
   $href->{Z}->[0]->[1] eq 'x'     &&
   $href->{Z}->[0]->[2] eq 'y'     &&
   $href->{Z}->[0]->[3] eq 'z'     &&
   $href->{Z}->[0]->[4] eq 'DELTA');

undef $href;
ok($commit_called);

exit(0);



sub my_commit {
    $commit_called = 1;
}
