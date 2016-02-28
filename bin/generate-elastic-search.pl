#!/usr/bin/env perl
use strict;
use FindBin qw($RealBin);
use lib "$RealBin/../src/perl5";
use JBlibs;

require Bio::JBrowse::Cmd::ElasticSearch;
exit Bio::JBrowse::Cmd::ElasticSearch->new(@ARGV)->run;

__END__

=head1 NAME

generate-elastic-search.pl - build a elastic-search index of feature 
names.

=head1 USAGE

  generate-elastic-search.pl               \
      [ --out <output directory> ]         \
      [ --url <url for elasticsearch> ]    \
      [ --verbose ]

=head1 OPTIONS

=over 4

=item --out <directory>

Data directory to process.  Default 'data/'.

=item --tracks <trackname>[,...]

Comma-separated list of which tracks to include in the names index.  If
not passed, all tracks are indexed.

=item --verbose

Print more progress messages.

=item --url

Add a URL to the elastic search (e.g. http://host.com:9200/) for elasticsearch.
Defaults to http://localhost:9200

=item --help | -h | -?

Print a usage message.

=back

=cut
