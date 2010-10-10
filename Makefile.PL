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

use_testml;

if (is_admin) {
    print "Module author removing inc/Pegex/\n";
    system("rm -fr inc/Pegex");
}

WriteAll;
