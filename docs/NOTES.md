# jbrowse_elasticsearch

## Notes



Drop database

    curl -XDELETE 'http://localhost:9200/_all?pretty=true'

Load database

    bin/generate-elastic-search.pl --out ../../sample_data/json/volvox/ --url http://localhost:3000 --verbose

Dump database

    elasticdump   --input http://localhost:9200 --output out.json
