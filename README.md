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

Then add the plugin to JBrowse by adding something similar to this to
trackList.json/jbrowse_conf.json (or the myriad other ways to add plugins)

    "plugins": ["ElasticSearch"]

And you're ready :)!

## Screenshot

![](img/example.png)


## Considerations

* For descriptions to be indexed, the `--nameAttributes` flag should be used
  with something like `--nameAttributes note,id,description,name` during
  flatfile-to-json.pl.

* http://localhost:4730 is the default express.js port, can be overridden in
  app.js and in --url param to generate-elastic-search.pl

* http://localhost:9200 is the default elasticsearch port, can be overridden in
  app.js and in --elasticurl param to generate-elastic-search.pl

## Feedback

Feel free to provide feedback, my first foray into elasticsearch!
