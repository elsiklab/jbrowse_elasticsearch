# generate-elastic-search.pl


A JBrowse add-on for indexing names with elasticsearch

## Installation

Get elastic search


    brew install elasticsearch


Add scripting to elasticsearch.yml (/usr/local/etc/elasticsearch/elasticsearch.yml);

    script.inline: true
    script.indexed: true
    


### Setup Node app


    npm install
    node app.js

## Application notes

We use scripting enabled to enable fancy upsert (combination of insert and
update into DB) so we aren't going to expose the API to the public.
Additionally, it is better to write a simple node wrapper script to match the
JBrowse/Store/Names/REST API format so that no JBrowse plugin is even needed.

Note: because of scripting enabled


## Example usage

First, you can clear out all your data

    curl -XDELETE 'http://localhost:9200/_all?pretty=true'


Load an example volvox track and index descriptions:

    flatfile-to-json.pl --nameAttributes note,id,description,name --gff docs/tutorial/data_files/volvox.gff3 --trackLabel test --trackType CanvasFeatures
    
Index the volvox data

    bin/generate-elastic-search.pl --out datadir --url http://localhost:4730


Note: that port 4730 is the default for the express.js app, it can be
overridden by a EXPRESS_PORT environment variable. Also, if your elasticsearch
DB is not localhost:9200 then use the --elasticurl flags

Then you can dump the database to JSON to confirm

    elasticdump   --input http://localhost:9200 --output out.json
    
Install elasticdump from NPM if needed

## Considerations

For descriptions to be indexed, the `--nameAttributes` flag should be used with
something like `--nameAttributes note,id,description,name` during
flatfile-to-json.pl.


Also note that with scripting enabled on the elasticsearch DB, it is best not
to expose the API to the public. This is basically the reason for the
express.js wrapper. This also avoids having to make a custom JBrowse plugin for
accessing the API, we just use the default REST Names API for JBrowse.
