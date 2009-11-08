use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::FluidDB',
    AUTHOR              => q{Xavier Noria <fxn@cpan.org>},
    VERSION_FROM        => 'lib/Net/FluidDB.pm',
    ABSTRACT_FROM       => 'lib/Net/FluidDB.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES=> {},
    PREREQ_PM => {
        'Test::Simple'           => '0.87', # because of done_testing()
        'LWP'                    => 0,
        'Moose'                  => 0,
        'MooseX::ClassAttribute' => 0,
        'JSON::XS'               => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-FluidDB-*' },
);
