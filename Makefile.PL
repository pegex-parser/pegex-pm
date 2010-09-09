use inc::Module::Install;

name 'Pegex';
all_from 'lib/Pegex.pm';

use_testml;

use_gloom 'Pegex::Base';

if (admin) {
    print "Module author removing inc/Pegex/\n";
    system("rm -fr inc/Pegex");
}

WriteAll;
