/**
 * Dialog box that prompts the user to choose between several
 * different available locations to navigate to.
 */

define([
           'dojo/_base/declare',
           'dojo/_base/array',
           'dojo/dom-construct',
           'dojo/on',
           'dojo/request',
           'dojo/aspect',
           'dijit/Dialog',
           'dijit/form/Button',
           'dijit/form/TextBox',
           'dijit/focus',
           'JBrowse/View/LocationList',
           'JBrowse/Util'
       ],
       function(
           declare,
           array,
           dom,
           on,
           request,
           aspect,
           Dialog,
           dijitButton,
           dijitTextBox,
           dijitFocus,
           LocationListView,
           Util
       ) {
return declare( null, {

    /**
     * @param args.browser the Browser object
     * @param args.locationChoices [Array] array of Location objects
     *   to choose from.  The locations can optionally have 'label',
     *   'description', and/or 'score' attributes, which will be
     *   displayed as columns.
     * @param args.title optional title of the dialog box.
     * @param args.prompt optional text prompt to show at the top of the dialog.
     * @param args.goCallback optional function to call for executing a 'Go' action. gets ( location, value, node, options )
     * @param args.showCallback optional function to call for executing a 'Show' action.  gets ( location, value, node, options)
     */
    constructor: function( args ) {
        this.browser = args.browser;
        this.config = dojo.clone( args.config || {} );
        this.locationChoices = [{label:'test',description:'test',start:0,end:100,ref:'ctgA'}];
        this.title = args.title || 'Choose location';
        this.prompt = args.prompt;
        this.goCallback = args.goCallback;
        this.showCallback = args.showCallback;
    },

    show: function() {
        var dialog = this.dialog = new Dialog(
            { title: this.title,
              className: 'locationChoiceDialog',
              style: { width: '70%' }
            }
            );
        var container = dom.create('div',{});

        // show the description if there is one
        var thisB = this;
        if( this.prompt ) {
            dom.create('div', {
                           className: 'prompt',
                           innerHTML: this.prompt
                       }, container );
            var subcontainer = dojo.create('div', { style: { 'padding-bottom': '10px' } }, container);
            dojo.create('img', { width: '16px', src: 'plugins/ElasticSearch/img/iconwiki.png', style: { 'padding-right': '5px' } }, subcontainer);
            var searchBox = new dijitTextBox({intermediateChanges: true}).placeAt(subcontainer);
            on(searchBox, "change", function() {
                request(thisB.browser.config.names.url, {
                    query: {
                        contains: searchBox.get('value')
                    },
                    handleAs: 'json'
                }).then(function(res) {
                    //thisB.locationListView.update(res);
                    var locations = array.map( res || [], function( obj ) {
                        l = obj.location;
                        return { locstring: Util.assembleLocString( l ),
                                 location: l,
                                 label: l.name || l.objectName,
                                 description: l.description,
                                 score: l.score,
                                 tracks: array.map( array.filter( l.tracks || [], function(t) { return t; }), // remove nulls
                                                    function(t) {
                                                        return t.key || t.name || t.label || t;
                                                    })
                                         .join(', ')
                               };
                    });
                    thisB.locationListView.grid.store.setData(locations);
                    thisB.locationListView.grid.refresh();
                });
            });
            this.searchBox = searchBox;
        }

        var browser = this.browser;
        this.locationListView = new LocationListView(
            { browser: browser,
              locations: this.locationChoices,
              buttons: [
                  {
                      className: 'show',
                      innerHTML: 'Show',
                      onClick: this.showCallback || function( location ) {
                          browser.showRegionAfterSearch( location );
                      }
                  },
                  {
                      className: 'go',
                      innerHTML: 'Go',
                      onClick: this.goCallback   || function( location ) {
                          dialog.hide();
                          browser.showRegionAfterSearch( location );
                      }
                  }
              ]
            },
            dom.create( 'div', {
                            className: 'locationList',
                            style: { maxHeight: 0.5*this.browser.container.offsetHeight+'px'}
                        },container)
        );

        this.actionBar = dojo.create( 'div', { className: 'infoDialogActionBar dijitDialogPaneActionBar' });
        new dijitButton({ iconClass: 'dijitIconDelete',
                          label: 'Cancel', onClick: dojo.hitch( dialog, 'hide' )
                        })
            .placeAt(this.actionBar);



        dialog.set( 'content', [ container, this.actionBar ] );
        dialog.show();

        this.locationListView.grid.store.setData([]);
        this.locationListView.grid.refresh();

        aspect.after( dialog, 'hide', dojo.hitch( this, function() {
                              dijitFocus.curNode && dijitFocus.curNode.blur();
                              setTimeout( function() {
                                  dialog.destroyRecursive();
                              }, 500 );
                      }));
    }
});
});
