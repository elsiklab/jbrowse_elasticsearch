# jbrowse_elasticsearch

[![Build Status](https://travis-ci.org/elsiklab/jbrowse_elasticsearch.svg?branch=master)](https://travis-ci.org/elsiklab/jbrowse_elasticsearch)

A JBrowse add-on for indexing names with elasticsearch

## Pre-requisites

- elasticsearch
- nodejs/npm
- cpanm

## Installation

Run the setup script

    bash setup.sh

Then load your tracks

    flatfile-to-json.pl --nameAttributes note,id,description,name --gff docs/tutorial/data_files/volvox.gff3 --trackLabel test --trackType CanvasFeatures

And then load the tracks into elasticsearch

    bin/generate-elastic-search.pl

Then add the plugin to JBrowse by adding something like this to trackList.json or `jbrowse_conf.json`

    "plugins": ["ElasticSearch"]

Finally start the helper app (starts app.js as middleware for elasticsearch queries)

    npm start


## Troubleshooting

* The setup.sh installs the jbrowse libs to the system with cpanm, if there are problems with setup.sh make sure cpanm is installed correctly

* For the gene descriptions to be indexed, the `--nameAttributes` flag should be used with something like `--nameAttributes name,description,other_field_to_index`. By default --nameAttributes is id,name,alias. The order of arguments in --nameAttributes is important, the first should be the unique name, id or symbol (or whatever is acceptable to appear in the name box in the popup). Other arguments after the first are then all associated with the first as descriptions, with multiple descriptions being allowed

## Example GFF

If you have a feature such as

    chr23  RefSeq  gene    2475803 2809862 .   -   .   ID=gene28777;Name=514682;Dbxref=NCBI_Gene:514682,BGD:BT30338;symbol_ncbi=PRIM2;description=primase%2C DNA%2C polypeptide 2 (58kDa);gene_synonym=PRIM2A;feature_type=Protein Coding


Then running

    flatfile-to-json.pl --trackLabel RefSeq --gff file.gff --nameAttributes symbol_ncbi,gene_synonym,description,dbxref

This would make `symbol_ncbi` the "primary key" and associate the `gene_synonym`, `description`, and `dbxref` as "descriptions" of that gene (the search box doesn't distinguish the field type, they all just become descriptions)



 
## Screenshot

![](img/example.png)



## Defaults

* http://localhost:4730 is the default express.js port, can be overridden in app.js and in --url param to generate-elastic-search.pl

* http://localhost:9200 is the default elasticsearch port, can be overridden in app.js and in --elasticurl param to generate-elastic-search.pl

## Feedback

Feel free to provide feedback, my first foray into elasticsearch!

