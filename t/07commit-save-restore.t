#!/usr/bin/perl -w
#
# $Id: 07commit-save-restore.t,v 1.3 2001/01/19 15:20:41 andrew Exp $
#
# Test commiting, saving and restoring sentient hashes.
#
# Attempts to serialize hashes containing nested perl objects and then
# reconstruct the hashes.
#
# Todo: class-specific Freeze/Thaw methods

use strict;
use Test;
use vars qw($serialized_val $href $data $tmp
	    $newval $newval2
	    $dd_tests $ft_tests $st_tests $xx_tests);


# See what serializers are available.

BEGIN {
    eval "use Data::Dumper;";
    $dd_tests = 3 unless $@;
    eval "use FreezeThaw ();";
    $ft_tests = 2 unless $@;
    eval "use Storable   ();";
    $st_tests = 2 unless $@;
}


# Declare our test plan and try to ensure that the module to be tested
# will be found if we are not run from the test harness

BEGIN { 
    plan tests => $dd_tests + $ft_tests + $st_tests;
    unshift @INC, 'lib', '../lib' unless grep /blib/, @INC;
}

use Tie::SentientHash;



# Commit function

sub my_commit {
    my($meta, $data) = @_;

    if ($meta->{SERIALIZE} eq 'FreezeThaw') {
	$serialized_val = FreezeThaw::freeze($data);
    }
    elsif ($meta->{SERIALIZE} eq 'Storable') {
	$serialized_val = Storable::freeze($data);
    }
    elsif ($meta->{SERIALIZE} eq 'Data::Dumper') {
	$serialized_val = Data::Dumper->Dump([$data], [qw($data)]);
    }
    else {
	warn "Serializer not specified\n";
    }
}


# Test Data::Dumper serializer

if ($dd_tests) {
    undef $href;
    undef $serialized_val;
    undef $data;
    $href = Tie::SentientHash->new( { TRACK_CHANGES => 1,
				      COMMIT_SUB    => \&my_commit,
				      SERIALIZE     => 'Data::Dumper' },
				    { SCALAR => 42 } );
    
    $href->{ARRAY} = [ 1, 2, 3 ];
    $href->{OBJ}   = bless { X => 1, Y => 2, Z => 3 }, 'TESTHASHOBJ';
    
    $tmp = !defined $serialized_val;
    undef $href;
    ok($tmp and length($serialized_val) > 1);
    
    eval "$serialized_val";
    ok (!$@);
    $href = Tie::SentientHash->new( { TRACK_CHANGES => 1 }, $data );

    ok(    exists $href->{SCALAR}
       and $href->{SCALAR} == 42
       and UNIVERSAL::isa($href->{ARRAY}, 'ARRAY')
       and UNIVERSAL::isa($href->{OBJ}, 'TESTHASHOBJ'));
}



# Test FreezeThaw serializer

if ($ft_tests) {
    undef $serialized_val;
    $href = Tie::SentientHash->new( { TRACK_CHANGES => 1,
				      COMMIT_SUB    => \&my_commit,
				      SERIALIZE     => 'FreezeThaw' },
				    { SCALAR => 42 } );
    
    $href->{ARRAY} = [ 1, 2, 3 ];
    $href->{OBJ}   = bless { X => 1, Y => 2, Z => 3 }, 'TESTHASHOBJ';
    
    $tmp = !defined $serialized_val;
    undef $href;
    ok($tmp and length($serialized_val) > 1);
    
    ($data) = FreezeThaw::thaw($serialized_val);
    $href = Tie::SentientHash->new( { TRACK_CHANGES => 1 }, $data );
    
    ok(    exists $href->{SCALAR}
       and $href->{SCALAR} == 42
       and UNIVERSAL::isa($href->{ARRAY}, 'ARRAY')
       and UNIVERSAL::isa($href->{OBJ}, 'TESTHASHOBJ'));
}


# Test Storable serializer

if ($st_tests) {
    undef $href;
    undef $serialized_val;
    $href = Tie::SentientHash->new( { TRACK_CHANGES => 1,
				      COMMIT_SUB    => \&my_commit,
				      SERIALIZE     => 'Storable' },
				    { SCALAR => 42 } );

    $href->{ARRAY} = [ 1, 2, 3 ];
    $href->{OBJ}   = bless { X => 1, Y => 2, Z => 3 }, 'TESTHASHOBJ';
    
    $tmp = !defined $serialized_val;
    undef $href;
    ok($tmp and length($serialized_val) > 1);
    
    $data = Storable::thaw($serialized_val);
    $href = Tie::SentientHash->new( { TRACK_CHANGES => 1 }, $data );
    

    ok(    exists $href->{SCALAR}
       and $href->{SCALAR} == 42
       and UNIVERSAL::isa($href->{ARRAY}, 'ARRAY')
       and UNIVERSAL::isa($href->{OBJ}, 'TESTHASHOBJ'));
}



