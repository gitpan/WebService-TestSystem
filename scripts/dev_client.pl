#!/usr/bin/perl -w

# This is a generic bit of code for use during testing; this will
# get turned into relevant sub-scripts later

use Getopt::Long;
use SOAP::Lite;
use strict;

my $soap = SOAP::Lite
    -> uri('http://www.osdl.org/WebService/TestSystem')
    -> proxy('http://mercury:8081/~bryce/cgi-bin/testsystem.pl');
# use SOAP::Lite +trace =>
#   [qw(transport dispatch result parameters method trace)];


my $testsys = $soap
    -> call(new => 0)
    -> result;

my $result;

die "Usage:  $0 [ command ]\n" unless (@ARGV>0);
my $cmd = shift @ARGV;

our %defines;
Getopt::Long::Configure ("bundling", "no_ignore_case");
GetOptions("define=s" => \%defines);

if ($cmd eq 'tests') {
    $result = $soap->get_tests($testsys, %defines);
} elsif ($cmd eq 'hosts') {
    $result = $soap->get_hosts($testsys, %defines);
} elsif ($cmd eq 'images') {
    $result = $soap->get_images($testsys, %defines);
} elsif ($cmd eq 'packages') {
    $result = $soap->get_packages($testsys, %defines);
} elsif ($cmd eq 'requests') {
    $result = $soap->get_requests($testsys, %defines);
} elsif ($cmd eq 'patches') {
    $result = $soap->get_patches($testsys, %defines);
} else {
    die "Unknown argument '$ARGV[0]'\n";
}

if ($result->fault) {
    print join ', ', 
    $result->faultcode,
    $result->faultstring;
    exit -1;
}

my @rows = @{$result->result};

foreach my $row (@rows) {
    print "--------------------\n";
    foreach my $key (keys %{$row}) {
        print $key, ": ", $row->{$key} || '', "\n";
    }
}



