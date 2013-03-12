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
    'jquery.ui':              'vendor/jquery-ui/jquery-ui-1.10.1.custom.min',
    'jquery.util':            'helpers/util',
    'jquery.tinysort':         'vendor/jquery.tinysort.min',
    'underscore':             'lib/underscore-min',
    'underscore.inflection':  'lib/underscore/underscore.inflection',
    'underscore.helpers':     'helpers/underscore',
    'backbone':               'lib/backbone-min',
    'backbone.nested':        'lib/backbone/deep-model.min',
    'text':                   'lib/text',
    'handlebars':             'lib/handlebars',
    'handlebars.helpers':     'helpers/handlebars',
    'hb':                     'lib/hbtemplate',
    'modernizr':              'vendor/modernizr',
    'shortcut':               'vendor/shortcut',
    'bootstrap':              'vendor/bootstrap/bootstrap',
    'pagehub':                'lib/pagehub',
    'pagehub.config':         'config',
    'pagehub.state':          'state',
    'jquery.gridster':        'lib/jquery.gridster.min',
    'inflection':             'vendor/inflection',
    'md5':                    "vendor/md5",
    'timed_operation':        "lib/timed_operation",
    'animable_view':          'views/shared/animable_view',
    'canvas-loader':          'vendor/heartcode-canvasloader-min'
    // 'codemirror',             'vendor/'
  },

  shim: {
    'jquery': { exports: '$' },
    'jquery.ui': [ 'jquery' ],
    'jquery.util': [ 'jquery' ],
    'jquery.gridster': [ 'jquery' ],
    'jquery.tinysort': [ 'jquery' ],

    'canvas-loader': { exports: 'canvas-loader' },

    'pagehub': {
      deps: [ 'shortcut', 'jquery', 'jquery.ui', 'jquery.util', 'shortcut', 'modernizr', 'canvas-loader' ],
      exports: 'UI'
    },

    'timed_operation': { deps: [ "underscore", "backbone" ], exports: 'timed_operation' },

    'underscore': {
      exports: '_'
    },

    'underscore.inflection': [ 'underscore' ],

    'shortcut':    { exports: 'shortcut' },
    'inflection':  [],
    'md5':         [],

    'backbone': {
      deps: [ "underscore", "jquery" ],
      exports: "Backbone"
    },

    'backbone.nested': [ 'backbone' ],

    'handlebars': {
      exports: 'Handlebars'
    }
  }
});

require([
  'pagehub.state',
  'pagehub.config',
  'underscore',
  'underscore.helpers',
  'jquery',
  'jquery.ui',
  'jquery.tinysort',
  'handlebars',
  'handlebars.helpers',
  'inflection',
  'md5',
  'shortcut'
], function(State) {
  var application = new State({});

  try       { if (pagehub_hooks); }
  catch(e)  { pagehub_hooks = []; }

  console.log("PageHub dependencies loaded. Running " + pagehub_hooks.length + " hooks.")

  _.each(pagehub_hooks, function(cb) {
    cb(application); return true;
  });

  delete pagehub_hooks;
});

