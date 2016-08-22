#!/bin/bash
set -eu -o pipefail
echo "Installing Perl pre-requisites"
cpanm .
cpanm --notest git://github.com/GMOD/jbrowse.git

echo "Installing NodeJS pre-requisites"
npm install

echo "Setting up test dataset"
prepare-refseqs.pl --fasta test/data/volvox.fa --out test/volvox
flatfile-to-json.pl --gff test/data/volvox.gff3 --out test/volvox --type mRNA --trackLabel volvox_transcript --trackType CanvasFeatures
flatfile-to-json.pl --gff test/data/volvox.gff3 --out test/volvox --trackLabel volvox --trackType CanvasFeatures
cat test/data/volvox.conf >> test/volvox/tracks.conf
cp test/data/*gz* test/volvox

echo "Done"
