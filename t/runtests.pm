
use strict;
use warnings;

use Test::More;

use FindBin;

use lib "$FindBin::RealBin/../blib/lib";
use Slay::Makefile;

BEGIN {
    eval "use Devel::Cover qw(-db $FindBin::RealBin/cover_db -silent 1
                              -summary 0 +ignore .* +select Makefile.pm)"
	if $ENV{COVER};
}

sub do_tests {
    my $base = $FindBin::RealBin;
    my ($myname) =  $FindBin::RealScript =~ /(.*)\.t$/;
    chdir $base;
    die "Error: No init directory for this test\n" unless -d "$myname.init";

    # First create the subdirectory for doing testing
    system "rm -rf $myname.dir" if -d "$myname.dir";
    system "cp -r $myname.init $myname.dir";

    chdir "$myname.dir";

    # Check to see if we need to skip all tests
    if (-f "skip.pl") {
	chomp (my $error = `$^X -I $base/blib/lib skip.pl 2>&1`);
	plan(skip_all => "$error") if $?;
    }

    my $sm = Slay::Makefile->new;
    $sm->parse("../Common.smak");
    $sm->maker->check_targets('test');

    # Get list of targets
    #    N.B.: there should be a way to do this without looking
    #    under the skirts of Slay::Maker.
    my ($target, $rule, $deps, $matches) = @{$sm->maker->{QUEUE}} ?
	@{$sm->maker->{QUEUE}[-1]} : ();
    my @tests = @ARGV ? @ARGV : defined $target && $deps ? @$deps : () ;
    plan tests => 0+@tests;
    foreach my $test (@tests) {
	$sm->make($test);
	my $ok = -r $test ? `cat $test` : "Failed to build $test";
	is ($ok, '', $test);
    }
}

1;
