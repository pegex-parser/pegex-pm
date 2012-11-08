BEGIN { $main::PM = 'lib/Pegex.pm' }
use inc::Module::Package 'Ingy:modern 0.20';

if (is_admin) {
    print "Module author removing inc/Pegex/\n";
    system("rm -fr inc/Pegex");
}

recommends 'YAML::XS';

clean_files 'nytprof*';
