# generate-elastic-search.pl


A JBrowse plugin for indexing names with elasticsearch

# install elasticsearch

    brew install elasticsearch


# delete all

    curl -XDELETE 'http://localhost:9200/_all' && echo


# dump all

    rm -f out.json && elasticdump   --input http://localhost:9200 --output out.json
