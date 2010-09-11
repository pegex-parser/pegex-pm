use inc::Module::Install;

name 'Pegex';
all_from 'lib/Pegex.pm';
readme_from;
manifest_skip;

use_gloom 'Pegex::Base';

use_testml;

if (admin) {
    print "Module author removing inc/Pegex/\n";
    system("rm -fr inc/Pegex");
}

WriteAll;
