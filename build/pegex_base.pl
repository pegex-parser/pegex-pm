#!/usr/bin/env perl

# Script to generate Pegex::Base from Moos.pm.

use IO::All;

use constant moos_pm_path => '../moos-pm/lib/Moos.pm';

my $header = "# Pegex::Base generated from Moos.pm\n\n";

my $code = io(moos_pm_path)->all;

$code =~ s/^##.*\n(#.*\n)*( *\n)*//m;
$code =~ s/^=head1.*//ms;
$code =~ s/Moos::Object/Pegex::Object/g;
$code =~ s/Moos/Pegex::Base/g;
$code =~ s/MOOS/PEGEX/g;
$code =~ s/^(our \$VERSION =)/# $1/m;

print $header . $code;
