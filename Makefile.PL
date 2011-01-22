use inc::Module::Install;

name 'Pegex';
all_from 'lib/Pegex.pm';
readme_from;
manifest_skip;
ack_xxx;
version_check;

# XXX Should probably add support for this.
# use_gloom 0.12 => 'Pegex::Base';
use_gloom 'Pegex::Base';

# XXX Recursive dependency between TestML and Pegex.
#
# If you are installing both of these from source, then comment out the
# following line. Install this module (without running tests), install
# TestML.pm normally, then uncomment out the following line and install this
# module the normal way (with tests).
#
# If you are installing from CPAN there is no bootstrap problem. Move along.
use_testml;

if (is_admin) {
    print "Module author removing inc/Pegex/\n";
    system("rm -fr inc/Pegex");
}

WriteAll;
