var elasticsearch = require('elasticsearch');
var express = require('express');
var app = express();


var client = new elasticsearch.Client({
    host: 'localhost:9200'
});


app.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

app.get('/', function(req, res) {
    var q = (req.query.equals || req.query.startswith || req.query.contains).toLowerCase();

    var fields = ['name'];
    var method = null;
    if (req.query.contains) {
        fields.push('description');
    }
    method = 'phrase_prefix';

    client.search({
        index: 'gene',
        type: 'loc',
        size: 50,
        body: {
            query: {
                multi_match: {
                    type: method,
                    query: q,
                    fields: fields
                }
            }
        }
    }).then(function(resp) {
        var hits = resp.hits.hits;
        var total = resp.hits.total;
        var ret = {};
        ret.hits = hits.map(function(obj) {
            return {
                name: obj._source.name,
                location: {
                    start: obj._source.start,
                    description: obj._source.description,
                    objectName: obj._source.name,
                    end: obj._source.end,
                    ref: obj._source.ref,
                    tracks: [obj._source.track_index]
                }
            };
        });
        ret.total = total;
        res.type('application/json');
        res.send(ret);
    }, function(err) {
        console.trace(err.message);
    });
});

app.listen(process.env.EXPRESS_PORT || 4730);
