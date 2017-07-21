var assert = require('assert');
var elasticsearch = require('elasticsearch');
require('es6-promise').polyfill();


var client = new elasticsearch.Client({
    host: 'localhost:9200',
    log: 'trace'
});

describe('ElasticSearch', function() {
    describe('#search', function() {
        it('search for basic gene', function(done) {
            client.search({
                q: 'Apple2',
                index: 'gene',
                type: 'loc'
            }).then(function(resp) {
                console.error(resp);
                assert.equal(resp.hits.hits[4]._source.description, 'mRNA with CDSs but no UTRs');
                done();
            }).catch(function(err) {
                done(err); //report error thrown in .then
            });
        });
        it('search for variant', function(done) {
            client.search({
                index: 'gene',
                type: 'loc',
                q: 'rs17882967'
            }).then(function(resp) {
                assert.equal(resp.hits.hits[0]._source.name, 'rs17882967');
                assert.equal(resp.hits.hits[0]._source.track_index, 'volvox_vcf_test');
                done();
            }).catch(function(err) {
                done(err); //report error thrown in .then
            });
        });
        it('search for description', function(done) {
            client.search({
                index: 'gene',
                type: 'loc',
                q: 'Ok'
            }).then(function(resp) {
                assert.equal(resp.hits.hits[0]._source.description, 'Ok! Ok! I get the message.');
                done();
            }).catch(function(err) {
                done(err); //report error thrown in .then
            });
        });
    });
});

