#!/usr/bin/perl -w
#
# $Id: 06nested-objects.t,v 1.3 2001/01/18 17:54:57 andrew Exp $
#
# Test nested hashes.


use strict;
use Test;
use vars qw($commit_called $href $modified $was_unmodified $newval $newval2);

# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => 16;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}

use Tie::SentientHash;

sub TESTSCALAROBJ::val_x2 {
	my($self) = @_;
	return $$self * 2;
}

sub TESTARRAYOBJ::val_x2 {
    my($self, $ix) = @_;
    return $self->[$ix] * 2;
}

sub TESTARRAYOBJ::set_el {
    my($self, $ix, $val) = @_;     
    return $self->[$ix] = $val;
}

sub TESTHASHOBJ::val_x2 {
    my($self, $key) = @_;     
    return $self->{$key} * 2;
}




my $scalarval = 42;
my $scalarref = \$scalarval;
$href = new Tie::SentientHash
                  { TRACK_CHANGES => 1,
		    COMMIT_SUB    => \&my_commit },
                  { W => bless($scalarref, 'TESTSCALAROBJ'),
		    X => bless([ 10, 9, 8], 'TESTARRAYOBJ'),
		    Y => bless({ A => 1,
				 B => bless({ B1 => 2 }, 'TESTHASHOBJ'),
				 C => 3 }, 'TESTHASHOBJ'),
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

$was_unmodified  = !exists $href->{NEW1} && !$modified->{NEW1};
eval { $href->{NEW1} = { NEW11 => $newval  = 42,
			 NEW12 => $newval2 = 43}; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{NEW1} &&
   $href->{NEW1}->{NEW11} == $newval  && 
   $href->{NEW1}->{NEW12} == $newval2 &&
   (keys %{$href->{NEW1}}) == 2);


# Test direct insertion of a new nested hash element

$was_unmodified = !$modified->{NEW2};
eval { $href->{NEW2}->{NEW21} = $newval = 'new hash element'; };
ok(!$@ &&
   $was_unmodified &&
   $modified->{NEW2} &&
   $href->{NEW2}->{NEW21} eq $newval &&
   (keys %{$href->{NEW2}}) == 1);


# Test that objects can be accessed

ok ($href->{W}->val_x2      == ${$href->{W}}   * 2);
ok ($href->{X}->val_x2(1)   == $href->{X}->[1] * 2);
ok ($href->{Y}->val_x2('A') == $href->{Y}->{A} * 2);
ok ($href->{Y}->{B}->val_x2('B1') == $href->{Y}->{B}->{B1} * 2);


# Test that object methods that change object data result in the
# element marked as being modified

$was_unmodified = !$modified->{X};
$href->{X}->set_el(2, 42);
ok ($was_unmodified &&
    $modified->{X} &&
    $href->{X}->[2] == 42);


# Explicitly cause the sentient hash to be destroyed

undef($href);
ok($commit_called);


undef $commit_called;
$href = Tie::SentientHash->new( { TRACK_CHANGES => 1,
				  COMMIT_SUB    => \&my_commit },
				bless({ A => 1,
					B => bless({ B1 => 2 }, 'TESTHASHOBJ'),
					C => 3 }, 'TESTHASHOBJ') );

ok($href->isa('TESTHASHOBJ') and (tied %$href)->modified == 0);
$href->{A} = 2;
ok(    (tied %$href)->modified == 1 
   and ((tied %$href)->modified)[0] eq 'A' );

undef $href;
ok($commit_called);

sub my_commit {
    $commit_called = 1;
}


exit(0);

