var assert = require('assert');
var elasticsearch = require('elasticsearch');

var client = new elasticsearch.Client({
    host: 'localhost:9200',
    log: 'trace'
});

describe('ElasticSearch', function() {
    describe('#search', function() {
        it('search for basic gene', function(done) {
            client.search({
                index: 'gene',
                type: 'loc',
                body: {
                    'sort': ['description'],
                    'query': {
                        'multi_match': {
                            'type': 'phrase_prefix',
                            'query': 'Apple2',
                            'fields': [ 'name', 'description' ]
                        }
                    }
                }
            }).then(function(resp) {
                assert.equal(resp.hits.total, 6);
                assert.equal(resp.hits.hits[4]._source.description, 'mRNA with CDSs but no UTRs');
                done();
            }, function(err) {
                throw err;
            });
        });
        it('search for variant', function(done) {
            client.search({
                index: 'gene',
                type: 'loc',
                body: {
                    'query': {
                        'multi_match': {
                            'type': 'phrase_prefix',
                            'query': 'rs17882967',
                            'fields': [ 'name', 'description' ]
                        }
                    }
                }
            }).then(function(resp) {
                assert.equal(resp.hits.total, 1);
                assert.equal(resp.hits.hits[0]._source.name, 'rs17882967');
                assert.equal(resp.hits.hits[0]._source.track_index, 'volvox_vcf_test');
                done();
            }, function(err) {
                throw err;
            });
        });
        it('search for description', function(done) {
            client.search({
                index: 'gene',
                type: 'loc',
                body: {
                    'query': {
                        'multi_match': {
                            'type': 'phrase_prefix',
                            'query': 'Ok!',
                            'fields': [ 'name', 'description' ]
                        }
                    }
                }
            }).then(function(resp) {
                assert.equal(resp.hits.total, 1);
                assert.equal(resp.hits.hits[0]._source.description, 'Ok! Ok! I get the message.');
                done();
            }, function(err) {
                throw err;
            });
        });
    });
});

