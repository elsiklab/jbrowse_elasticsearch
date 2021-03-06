var elasticsearch = require('elasticsearch');
var baseURI = require('base-uri');
var express = require('express');
var app = express();

var router = express.Router();

var client = new elasticsearch.Client({
    host: 'localhost:9200'
});


app.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});
var router = express.Router();
router.get('/', function(req, res) {
    var q = (req.query.equals || req.query.startswith || req.query.contains || '').toLowerCase();
    var exact = req.query.exact == "true";
    var query = {
        index: 'gene'+(req.query.index||''),
        type: 'loc',
        size: 50
    };

    if(exact) {
        query.q = q;
    } else {
        query.body = {
            query: {
                multi_match: {
                    type: 'phrase_prefix',
                    query: q,
                    fields: [ 'name', 'description' ]
                }
            }
        }
    }


    client.search(query).then(function(resp) {
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


app.use(baseURI, router);

module.exports = app;
