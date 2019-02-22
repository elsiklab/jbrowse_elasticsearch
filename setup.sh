#!/bin/bash
set -eu -o pipefail

echo "Installing Perl pre-requisites"
cpanm --notest .
cpanm --notest https://github.com/GMOD/jbrowse/archive/master.tar.gz

echo "Installing NodeJS pre-requisites"
npm install

echo "Setting up test dataset"
prepare-refseqs.pl --fasta test/data/volvox.fa --out test/volvox
flatfile-to-json.pl --gff test/data/volvox.gff3 --out test/volvox --type mRNA --trackLabel volvox_transcript --trackType CanvasFeatures --nameAttributes name,alias,id,description,note
flatfile-to-json.pl --gff test/data/volvox.gff3 --out test/volvox --trackLabel volvox --trackType CanvasFeatures --nameAttributes name,alias,id,description,note
cat test/data/volvox.conf > test/volvox/tracks.conf
cp test/data/*gz* test/volvox

echo "Done"
