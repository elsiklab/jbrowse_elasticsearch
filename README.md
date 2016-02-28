# jbrowse_elasticsearch

![build staus](https://travis-ci.org/cmdcolin/jbrowse_elasticsearch.svg?branch=master)

A JBrowse add-on for indexing names with elasticsearch

## Installation

Get elastic search


    brew install elasticsearch

Setup Node app

    npm install
    node app.js

Then load your tracks

    flatfile-to-json.pl --nameAttributes note,id,description,name --gff docs/tutorial/data_files/volvox.gff3 --trackLabel test --trackType CanvasFeatures

And create the index

    bin/generate-elastic-search.pl --out datadir --url http://localhost:4730

And you're ready :)!

## Screenshot

![](img/example.png)

Normally the description ("Ok ok! I get the message") would not be indexed


## Considerations

* For descriptions to be indexed, the `--nameAttributes` flag should be used
  with something like `--nameAttributes note,id,description,name` during
  flatfile-to-json.pl.


* Port 4730 is the default port for the express.js app, it can be
  overridden by a EXPRESS_PORT environment variable. Also, if your elasticsearch
  DB is not localhost:9200 then use the --elasticurl flags


* With scripting enabled on the elasticsearch DB, it is best not to expose the
  API http://localhost:9200 publically.

  * This also gives us a good reason to just use the express.js wrapper for the 
    JBrowse REST Names API instead of writing our own custom JBrowse plugin to adapt
    to the elasticsearch API.


## Feedback

Feel free to provide feedback, my first foray into elasticsearch!
