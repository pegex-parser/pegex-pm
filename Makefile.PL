use inc::Module::Install;

name 'Pegex';
all_from 'lib/Pegex.pm';

use_gloom 'Pegex::Base';

WriteAll;
