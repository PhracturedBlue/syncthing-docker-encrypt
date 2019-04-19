#!/usr/bin/perl

use strict;
use warnings;

my $key = shift(@ARGV);
my $pass = shift(@ARGV);
while (length($pass) < length($key)) {
    $pass .= $pass;
}
my @a = map {ord($_)} split(//, $key);
my @b = map {ord($_)} split(//, $pass);
print "char key[] = {";
for (0 .. $#a) {
    printf "%d, ", $a[$_] ^ $b[$_];
}
print "};\n";
