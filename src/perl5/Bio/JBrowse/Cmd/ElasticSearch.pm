package Bio::JBrowse::Cmd::ElasticSearch;

=head1 NAME

Bio::JBrowse::Cmd::ElasticSearch - generate-elastic-search.pl.

=cut

use strict;
use warnings;


use base 'Bio::JBrowse::Cmd';

use Search::Elasticsearch ();
use File::Spec ();
use POSIX ();
use Storable ();
use File::Path ();
use File::Temp ();
use List::Util ();

use GenomeDB ();
use Bio::JBrowse::ElasticStore ();

sub option_defaults {(
    dir => 'data',
    completionLimit => 20,
    locationLimit => 100,
    url => '/elasticsearch/',
    elasticurl => 'http://localhost:9200',
    mem => 256 * 2**20,
    tracks => [],
)}

sub option_definitions {(
    "dir|out=s",
    "verbose|v+",
    "elasticurl=s",
    "url=s",
    "help|h|?",
    'tracks=s@'
)}

sub initialize {
    my ( $self ) = @_;
    $self->{e} = Search::Elasticsearch->new(
        nodes => $self->opt('elasticurl')
    );
}

sub run {
    my ( $self ) = @_;

    my $outDir = $self->opt('dir');
    -d $outDir or die "Output directory '$outDir' does not exist.\n";
    -w $outDir or die "Output directory '$outDir' is not writable.\n";
    my $gdb = GenomeDB->new( $outDir );

    my $refSeqs = $gdb->refSeqs;
    unless( @$refSeqs ) {
        die "No reference sequences defined in configuration, nothing to do.\n";
    }
    my @tracks = grep $self->track_is_included( $_->{label} ),
                      @{ $gdb->trackList || [] };
    unless( @tracks ) {
        die "No tracks. Nothing to do.\n";
    }

    $self->vprint( "Tracks:\n".join('', map "    $_->{label}\n", @tracks ) );

    # find the names files we will be working with
    my $names_files = $self->find_names_files( \@tracks, $refSeqs );
    unless( @$names_files ) {
        warn "WARNING: No feature names found for indexing,"
             ." only reference sequence names will be indexed.\n";
    }

    $self->load( $refSeqs, $names_files );

    # store the list of tracks that have names
    $self->name_store->meta->{track_names} = [
        $self->_uniq(
            @{$self->name_store->meta->{track_names}||[]},
            @{$self->{stats}{tracksWithNames}}
        )
    ];

    # record the fact that all the keys are lowercased
    $self->name_store->meta->{lowercase_keys} = 1;

    # set up the name store in the trackList.json
    $gdb->modifyTrackList( sub {
                               my ( $data ) = @_;
                               $data->{names}{type} = 'JBrowse/Store/Names/REST';
                               $data->{names}{url}  = $self->opt('url');
                               return $data;
                           });
    return;
}

sub load {
    my ( $self, $ref_seqs, $names_files ) = @_;

    # convert the stream of name records into a stream of operations to do
    # on the data in the hash store
    my $operation_stream = $self->make_operation_stream( $self->make_name_record_stream( $ref_seqs, $names_files ), $names_files );

    # hash each operation and write it to a log file
    $self->name_store->stream_do(
        $operation_stream,
        sub {
            my ( $operation, $data ) = @_;
            my %fake_store = ( $operation->[0] => $data );
            $self->do_hash_operation( \%fake_store, $operation );
            return $fake_store{ $operation->[0] } ;
        },
        $self->{stats}{operation_stream_estimated_count},
    );

}

sub name_store {
    my ( $self ) = @_;
    unless( $self->{name_store} ) {
        $self->{name_store} = tie my %tied_hash, 'Bio::JBrowse::ElasticStore', (
                dir   => File::Spec->catdir( $self->opt('dir'), "names" ),
                work_dir => $self->opt('workdir'),
                verbose => $self->opt('verbose')
        );
        $self->{name_store_tied_hash} = \%tied_hash;
    }
    return $self->{name_store};
}
sub make_file_record {
    my ( $self, $track, $file ) = @_;
    -f $file or die "$file not found\n";
    -r $file or die "$file not readable\n";
    my $gzipped = $file =~ /\.(txt|json|g)z$/;
    my $type = $file =~ /\.txtz?$/      ? 'txt'  :
               $file =~ /\.jsonz?$/     ? 'json' :
               $file =~ /\.vcf(\.gz)?$/ ? 'vcf'  :
               $file =~ /\.gff(\.gz)?$/ ? 'gff'  :
                                           undef;

    if( $type ) {
        return { gzipped => $gzipped, fullpath => $file, type => $type, trackName => $track->{label} };
    }
    return;
}

sub track_is_included {
    my ( $self, $trackname ) = @_;
    my $included = $self->{included_track_names} ||= do {
        my @tracks = @{ $self->opt('tracks') };
        my $inc = { map { $_ => 1 } map { split ',', $_ } @tracks };
        @tracks ? sub { $inc->{ shift() } } : sub { 1 };
    };
    return $included->( $trackname );
}


my $OP_ADD_EXACT  = 1;
my $OP_ADD_PREFIX = 2;

sub make_operations {
    my ( $self, $record ) = @_;

    my $lc_name = lc $record->[0];
    unless( defined $lc_name ) {
        unless( $self->{already_warned_about_blank_name_records} ) {
            warn "WARNING: some blank name records found, skipping.\n";
            $self->{already_warned_about_blank_name_records} = 1;
        }
        return;
    }

    my @ops = ( [ $lc_name, $OP_ADD_EXACT, $record ] );

    $self->{stats}{operations_made} += scalar @ops;

    return @ops;
}


sub make_name_record_stream {
    my ( $self, $refseqs, $names_files ) = @_;
    my @names_files = @$names_files;

    my $name_records_iterator = sub {};
    my @namerecord_buffer;

    # insert a name record for all of the reference sequences
    for my $ref ( @$refseqs ) {
        $self->{stats}{name_input_records}++;
        $self->{stats}{namerecs_buffered}++;
        my $rec = [ @{$ref}{ qw/ name length name seqDir start end seqChunkSize/ }];
        $self->{stats}{total_namerec_bytes} += length join(",",$rec);
        push @namerecord_buffer, $rec;
    }


    my %trackHash;
    my $trackNum = 0;

    my $names_dir = File::Spec->catdir( $self->opt('dir'), "names" );
    if( -e File::Spec->catfile( $names_dir,'meta.json' ) ) {

        # read meta.json data into a temp HashStore
        my $temp_store = tie my %temp_hash, 'Bio::JBrowse::ElasticStore', (
                    dir   => $names_dir,
                    empty => 0,
                    compress => 0,
                    verbose => 0);

        # initialize the track hash with an index 
        foreach (@{$temp_store->meta->{track_names}}) {
            $trackHash{$_}=$trackNum++;
        }

        untie $temp_store;
    }


    return sub {
        while( ! @namerecord_buffer ) {
            my $nameinfo = $name_records_iterator->() || do {
                my $file = shift @names_files;
                return unless $file;
                $name_records_iterator = $self->make_names_iterator( $file );
                $name_records_iterator->();
            } or return;
            my @aliases = map { ref($_) ? @$_ : $_ }  @{$nameinfo->[0]};
            foreach my $alias ( @aliases ) {
                    my $track = $nameinfo->[1];
                    unless ( defined $trackHash{$track} ) {
                        $trackHash{$track} = $trackNum++;
                        push @{$self->{stats}{tracksWithNames}}, $track;
                    }
                    $self->{stats}{namerecs_buffered}++;
                    push @namerecord_buffer, [
                        $alias,
                        $trackHash{$track},
                        @{$nameinfo}[2..$#{$nameinfo}]
                        ];
            }
        }
        return shift @namerecord_buffer;
    };
}

sub do_hash_operation {
    my ( $self, $store, $op ) = @_;

    my ( $lc_name, $op_name, $record ) = @$op;

    if($self->opt('verbose')) {
        print "$lc_name\n";
    }

    # not allowed to index names with '.'
    if($lc_name ne '.') {
        $self->{e}->index(
            index   => 'gene',
            type    => 'loc',
            body    => {
                description => $lc_name,
                name => $record->[2],
                track_index => $self->name_store->meta->{track_names}[$record->[1]],
                ref => $record->[3],
                start => $record->[4],
                end => $record->[5]
            }
        );
    }
}



sub find_names_files {
    my ( $self, $tracks, $refseqs ) = @_;

    my @files;
    for my $track (@$tracks) {
        for my $ref (@$refseqs) {
            my $dir = File::Spec->catdir(
                $self->opt('dir'),
                "tracks",
                $track->{label},
                $ref->{name}
                );

            # read either names.txt or names.json files
            my $name_records_iterator;
            my $names_txt  = File::Spec->catfile( $dir, 'names.txt'  );
            if( -f $names_txt ) {
                push @files, $self->make_file_record( $track, $names_txt );
            }
            else {
                my $names_json = File::Spec->catfile( $dir, 'names.json' );
                if( -f $names_json ) {
                    push @files, $self->make_file_record( $track, $names_json );
                }
            }
        }

        # try to detect VCF tracks and index their VCF files
        if( $track->{storeClass}
            && ( $track->{urlTemplate} && $track->{urlTemplate} =~ /\.vcf\.gz/
             || $track->{storeClass} =~ /VCFTabix$/ )
            ) {
            my $path = File::Spec->catfile( $self->opt('dir'), $track->{urlTemplate} );
            if( -r $path ) {
                push @files, $self->make_file_record( $track, $path );
            }
            else {
                warn "VCF file '$path' not found, or not readable.  Skipping.\n";
            }
        }

    }

    return \@files;
}

sub make_operation_stream {
    my ( $self, $record_stream, $names_files ) = @_;
    my @operation_buffer;
    return sub {
        unless( @operation_buffer ) {
            if( my $name_record = $record_stream->() ) {
                push @operation_buffer, $self->make_operations( $name_record );
            }
        }
        return shift @operation_buffer;
    };
}

# each of these takes an input filename and returns a subroutine that
# returns name records until there are no more, for either names.txt
# files or old-style names.json files
sub make_names_iterator {
    my ( $self, $file_record ) = @_;
    if( $file_record->{type} eq 'txt' ) {
        my $input_fh = $self->open_names_file( $file_record );
        # read the input json partly with low-level parsing so that we
        # can parse incrementally from the filehandle.  names list
        # files can be very big.
        return sub {
            my $t = <$input_fh>;
            if( $t ) {
                $self->{stats}{name_input_records}++;
                $self->{stats}{total_namerec_bytes} += length $t;
                return eval { JSON::from_json( $t ) };
            }
            return undef;
        };
    }
    elsif( $file_record->{type} eq 'json' ) {
        # read old-style names.json files all from memory
        my $input_fh = $self->open_names_file( $file_record );

        my $data = JSON::from_json(do {
            local $/;
            my $text = scalar <$input_fh>;
            $self->{stats}{total_namerec_bytes} += length $text;
            $text;
        });

        $self->{stats}{name_input_records} += scalar @$data;

        return sub { shift @$data };
    }
    elsif( $file_record->{type} eq 'vcf' ) {
        my $input_fh = $self->open_names_file( $file_record );
        no warnings 'uninitialized';
        return sub {
            my $line;
            while( ($line = <$input_fh>) =~ /^#/ ) {}
            return unless $line;

            $self->{stats}{name_input_records}++;
            $self->{stats}{total_namerec_bytes} += length $line;

            my ( $ref, $start, $name, $basevar ) = split "\t", $line, 5;
            $start--;
            return [[$name],$file_record->{trackName},$name,$ref, $start, $start+length($basevar)];
        };
    }
    else {
        warn "ignoring names file $file_record->{fullpath}.  unknown type $file_record->{type}.\n";
        return sub {};
    }
}

sub open_names_file {
    my ( $self, $filerec ) = @_;
    my $infile = $filerec->{fullpath};
    if( $filerec->{gzipped} ) {
        # can't use PerlIO::gzip, it truncates bgzipped files
        my $z;
        eval {
            require IO::Uncompress::Gunzip;
            $z = IO::Uncompress::Gunzip->new( $filerec->{fullpath }, -MultiStream => 1 )
                or die "IO::Uncompress::Gunzip failed: $IO::Uncompress::Gunzip::GunzipError\n";
        };
        if( $@ ) {
            # fall back to use gzip command if available
            if( `which gunzip` ) {
                open my $fh, '-|', 'gzip', '-dc', $filerec->{fullpath}
                   or die "$! running gunzip";
                return $fh;
            } else {
                die "cannot uncompress $filerec->{fullpath}, could not use either IO::Uncompress::Gunzip or gzip";
            }
        }
        else {
            return $z;
        }
    }
    else {
        open my $fh, '<', $infile or die "$! reading $infile";
        return $fh;
    }
}

sub _hash_operation_freeze { $_[1] }
sub _hash_operation_thaw   { $_[1] }

sub _uniq {
    my $self = shift;
    my %seen;
    return grep !($seen{$_}++), @_;
}

1;
