#!/usr/bin/perl -w

# $Id: test.pl,v 1.3 2001/01/18 17:54:57 andrew Exp $
#

# This is now mostly an empty shell I experiment with.
# The real tests have moved to t/*.t
# See t/*.t for more detailed tests.


BEGIN {
    $| = 1;
    eval "require blib; import blib;";	# wasn't in 5.003, hence the eval
    warn $@ if $@;
}

use Tie::SentientHash;
use vars qw($count $t $s);
require Benchmark;
print "Testing SentientHash creation/destruction speed...\n";

$count = 10000;

$t = Benchmark::timeit($count, '$href =  {  }');
$s = $t->cpu_a;
printf "$count   empty hashes  cycled in %.2f cpu+sys seconds (%d per sec, %.2f millisecs/cycle)\n",
  $s, $count / $s, 1000 * $s / $count;


$t = Benchmark::timeit($count, '$href = new Tie::SentientHash {  }');
$s = $t->cpu_a;
printf "$count   empty objects cycled in %.2f cpu+sys seconds (%d per sec, %.2f millisecs/cycle)\n",
  $s, $count / $s, 1000 * $s / $count;


$t = Benchmark::timeit($count, '$href = { A => 42,
                                          B => [1, 2, 3],
                                          C => { X => 1, Y => 2 },
                                                 D => \undef }');
$s = $t->cpu_a;
printf "$count complex hashes  cycled in %.1f cpu+sys seconds (%d per sec, %.2f millisecs/cycle)\n",
  $s, $count / $s, 1000 * $s / $count;

$t = Benchmark::timeit($count, 'new Tie::SentientHash { TRACK_CHANGES => 1 },
                                                      { A => 42,
                                                        B => [1, 2, 3],
                                                        C => { X => 1, Y => 2 },
                                                        D => \undef }');
$s = $t->cpu_a;
printf "$count complex objects cycled in %.1f cpu+sys seconds (%d per sec, %.2f millisecs/cycle)\n",
  $s, $count / $s, 1000 * $s / $count;


# end.
