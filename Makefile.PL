# -*- perl -*-

use strict;
use ExtUtils::MakeMaker;
use Getopt::Long ();

use vars qw($opt_config);
Getopt::Long::GetOptions('config');

my $ok = 1;
my %prereq;
$prereq{'Data::Dumper'} = 0;
print "Checking for Data::Dumper ... ";
if (!eval { require Data::Dumper }) {
    $ok = 0;
    print "\nYou don't have installed the Data::Dumper module.\n";
} else {
    print "ok\n";
}

$prereq{'IO::AtomicFile'} = 0;
print "Checking for IO::AtomicFile ... ";
if (!eval { require IO::AtomicFile }) {
    $ok = 0;
    print "\nYou don't have installed the IO::AtomicFile module.\n";
} else {
    print "ok\n";
}

$prereq{'HTML::EP'} = 0;
print "Checking for HTML::EP ... ";
if (!eval { require HTML::EP }) {
    $ok = 0;
    print "\nYou don't have installed the HTML::EP package.\n";
} else {
    print "ok\n";
}

$prereq{'Wizard'} = 0;
print "Checking for Wizard ... ";
eval { require Wizard }
    or ($ok = 0  and
	print "\nYou don't have installed the Wizard module.\n");
unless ($ok) {
    print q{
Missing modules are available from any CPAN mirror, in particular
	ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module
};
    exit 1;
}
print "ok\n";

my $cfg;
if (-f "lib/Wizard/Examples/LDAP/Config.pm") {
    $cfg = eval { require "lib/Wizard/Examples/LDAP/Config.pm" };
}
if (!$cfg  ||  $opt_config) {
    my $prefsfile = $cfg->{'ldap-prefs-file'} || '/etc/Wizard-LDAP/prefs';
    $cfg->{'ldap-prefs-file'} =
	prompt("Enter path of the LDAP Wizard prefs file:", $prefsfile);
}
die "Failed to create directory lib/Wizard/Examples/LDAP: $!"
    unless ((-d "lib/Wizard/Examples/LDAP")  or
	    mkdir("lib/Wizard/Examples/LDAP", 0755));
my $dump = Data::Dumper->new([$cfg],
			     ["Wizard::Examples::LDAP::Config::config"]);
$dump->Indent(1);
if (!open(FILE, ">lib/Wizard/Examples/LDAP/Config.pm")  or
    !(print FILE ("package Wizard::Examples::LDAP::Config;\n",
		  $dump->Dump()))  or
    !close(FILE)) {
    die "Failed to create file lib/Wizard/Examples/LDAP/Config.pm: $!";
}

my %opts = ('NAME'         => 'Wizard-LDAP',
	    'VERSION_FROM' => 'lib/Wizard/Examples/LDAP.pm',
	    'EXE_FILES'    => ['ldapAdmin', 'ldapWizard'],
	    'dist'         => { 'SUFFIX'       => ".gz",
				'DIST_DEFAULT' => 'all tardist',
				'COMPRESS'     => "gzip -9f" },
	    'clean'        => { 'FILES' => '$(EXE_FILES)' });
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
#    $opts{ABSTRACT_FROM} = 'lib/Wizard/SaveAble/LDAP.pm';
    $opts{AUTHOR} = 'Jochen Wiedmann (joe@ispsoft.de) and Amarendran R. Subramanian (amar@ispsoft.de)';
    $opts{PREREQ_PM} = \%prereq;
}


WriteMakefile(%opts);


package MY;

sub libscan {
    my $self = shift;  my $path = shift;
    return undef if $path =~ /\~$/; # Emacs backup file
    $path;
}
