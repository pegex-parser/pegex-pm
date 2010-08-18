use inc::Module::Install;

name 'Pegex';
all_from 'lib/Pegex.pm';

test_requires 'YAML::XS';

use_testml;

use_gloom 'Pegex::Base';

WriteAll;
