#!/bin/bash

#dropdb
curl -XDELETE 'http://localhost:9200/_all?pretty=true'

#load data
flatfile-to-json.pl --gff test/volvox.gff3 --trackLabel volvox --trackType CanvasFeatures --nameAttributes name,id,description,note --out test/volvox
flatfile-to-json.pl --gff test/volvox.gff3 --type mRNA --trackLabel volvox_transcript --trackType CanvasFeatures --nameAttributes name,id,description,note --out test/volvox
prepare-refseqs.pl --fasta test/volvox.fa --out test/volvox

#generate elastic index
bin/generate-elastic-search.pl --out test/volvox
