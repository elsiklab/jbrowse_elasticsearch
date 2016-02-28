define( [
            'dojo/_base/declare',
            'dojo/_base/array',
            'dojo/store/util/QueryResults',
            'dojo/request/xhr',
            'dojo/io-query'
        ],
        function(
            declare,
            array,
            QueryResults,
            xhr,
            ioQuery
        ) {

return declare( null,
{
    constructor: function( args ) {
        this.url = args.url;
    },

    query: function( query, options ) {
        var thisB = this;
        //curl 'http://localhost:9200/blog/post/_search?q=user:dilbert&pretty=true'

        var op = 'q';
        var name = ''+query.name;
        if( /\*$/.test( name ) ) {
            name = name.replace(/\*$/,'');
            op = 'q';
        }
        var myquery = {};
        myquery[q] = name;

        return xhr( thisB.url+"?"+ioQuery.objectToQuery( myquery ),
                    { handleAs: "json" }
        ).then(function(data){
            console.log(data);
            return QueryResults( data );
        }, function(err){
            // Handle the error condition
            return QueryResults( [] );
        });
    },

    get: function( id ) {
        return this.query(id, undefined);
    },

    getIdentity: function( object ) {
        return object.id;
    }

});
});
