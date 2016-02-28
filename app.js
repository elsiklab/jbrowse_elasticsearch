var elasticsearch = require('elasticsearch');
var express = require('express');
var app = express();


var client = new elasticsearch.Client({
    host: 'localhost:9200'
});


app.use(function(req, res, next) {
    res.header("Access-Control-Allow-Origin", "*");
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
    next();
});

app.get('/', function(req, res) {
    var q=(req.query.equals || req.query.startswith).toLowerCase();
    client.search({
        index: 'gene',
        type: 'loc',
        body: {
            "query": {
                "multi_match" : {
                    "type": "phrase_prefix",
                    "query": q,
                    "fields": [ "name", "description" ] 
                }
            }
        }
    }).then(function (resp) {
        var hits = resp.hits.hits;
        var ret = hits.map(function(obj) {
            return {
                "name": obj._source.name,
                "location": {
                    "start": obj._source.start,
                    "end": obj._source.end,
                    "ref": obj._source.ref,
                    "tracks": [obj._source.track_index],
                    "objectName" : obj._source.name 
                }
            };
        });
        res.type('application/json');
        res.send(ret);
    }, function (err) {
        console.trace(err.message);
    });
});



app.listen(process.env.EXPRESS_PORT || 4730);
