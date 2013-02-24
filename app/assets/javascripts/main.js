requirejs.config({
  //By default load any module IDs from js/lib
  baseUrl: '/assets',
  //except, if the module ID starts with "app",
  //load it from the js/app directory. paths
  //config is relative to the baseUrl, and
  //never includes a ".js" extension since
  //the paths config could be for a directory.
  // <script type="text/javascript" src="/js/modernizr.js"></script>
  // <script type="text/javascript" src="/js/json2.min.js"></script>
  // <script type="text/javascript" src="/js/bootstrap/js/bootstrap.min.js"></script>
  //   <script type="text/javascript" src="/js/shortcut.js"></script>
  //   <script src="/js/dynamism.js"></script>
  //   <script src="/js/pagehub.js"></script>
  //   <script src="/js/pagehub_ui.js"></script>  
  paths: {
    // jquery:     '          lib/require-jquery',
    'jquery':                 'vendor/jquery-1.9.1.min',
    'jquery.ui':              'vendor/jquery-ui-1.10.1.custom.min',
    'jquery.util':            'helpers/util',
    'underscore':             'lib/underscore-min',
    'underscore.inflection':  'lib/underscore/underscore.inflection',
    'backbone':               'lib/backbone-min',
    'backbone.nested':        'lib/backbone/deep-model.min',
    'text':                   'lib/text',
    'handlebars':             'lib/handlebars',
    'handlebars.helpers':     'helpers/handlebars',
    'hb':                     'lib/hbtemplate',
    'modernizr':              'vendor/modernizr',
    'shortcut':               'vendor/shortcut',
    'bootstrap':              'vendor/bootstrap.min',
    'pagehub':                'lib/pagehub',
  },

  shim: {
    'jquery': { exports: '$' },
    'jquery.ui': [ 'jquery' ],
    'jquery.util': [ 'jquery' ],
    
    'pagehub': {
      deps: [ 'jquery', 'jquery.ui', 'jquery.util', 'shortcut', 'modernizr' ],
      exports: 'ui'
    },
    
    'underscore': {
      exports: '_'
    },
    
    'underscore.inflection': [ 'underscore' ],
    
    'backbone': {
      deps: [ "underscore", "jquery" ],
      exports: "Backbone"
    },
    
    'backbone.nested': [ 'backbone' ],
    
    'handlebars': {
      deps: [ 'underscore.inflection' ],
      exports: 'Handlebars'
    },
    'handlebars.helpers': [ 'handlebars' ],
    
    'shortcut': {
      exports: 'shortcut'
    }
  }
});

require([ 'underscore', 'handlebars', 'handlebars.helpers' ], function(_) { 
  _.each(pagehub_hooks, function(cb) { cb(); });
});

