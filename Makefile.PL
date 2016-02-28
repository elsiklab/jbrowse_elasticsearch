
use strict;
use warnings;



use File::Find;
use ExtUtils::MakeMaker 6.30;


my %libhash;
find(sub {
    my $dest=$File::Find::name;
    my $src=$dest;
    if(/pm$/) {
        $dest=~ s/src\/perl5\///;
        $libhash{$src}='$(INST_LIB)/'.$dest;
    }
}, "src/perl5");

my %WriteMakefileArgs = (
  "ABSTRACT" => "A tool to index jbrowse data with elasticsearch.",
  "AUTHOR" => "Colin Diesh",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "jbrowse_elasticsearch",
  "EXE_FILES" => [
    "bin/generate-elastic-search.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "jbrowse_elasticsearch",
  "PREREQ_PM" => {
    "Search::Elasticsearch" => 0
  },
  "VERSION" => "1.0",
  "test" => {
    "TESTS" => "t/*.t"
  },
  "PM" => \%libhash
);


WriteMakefile(%WriteMakefileArgs);



