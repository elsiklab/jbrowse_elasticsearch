define([
           'dojo/_base/declare',
           'dojo/dom',
           'JBrowse/Plugin',
           'ElasticSearch/View/Dialog/Search',
           'dijit/MenuItem',
           'dijit/registry',
           'dojo/dom-construct'
       ],
       function(
           declare,
           dom,
           JBrowsePlugin,
           LocationChoiceDialog,
           dijitMenuItem,
           registry,
           domConstruct
       ) {
return declare( JBrowsePlugin,
{
    constructor: function( args ) {
        this.browser = args.browser;

        // do anything you need to initialize your plugin here
        console.log( "ElasticSearch plugin starting" );

        this.browser.afterMilestone('initView', dojo.hitch(this,'initSearchMenu'));
    },
    initSearchMenu: function()  {
        var thisB = this;
        this.browser.addGlobalMenuItem( 'tools',
            new dijitMenuItem({
                id: 'menubar_search',
                label: "ElasticSearch",
                onClick: function() {
                    new LocationChoiceDialog({
                        browser: thisB.browser,
                        locationList: [],
                        title: 'ElasticSearch',
                        prompt: 'ElasticSearch interface'
                    }).show();
                }
            })
        );
        
        setTimeout(function() {
            if( !registry.byId("dropdownmenu_tools") ) {
                thisB.browser.renderGlobalMenu( 'tools', {text: 'Tools'}, thisB.browser.menuBar );
                var toolsMenu = registry.byId('dropdownbutton_tools');
                var helpMenu = registry.byId('dropdownbutton_help');
                domConstruct.place(toolsMenu.domNode, helpMenu.domNode, 'before');
            }
        }, 200);
    }
});
});
