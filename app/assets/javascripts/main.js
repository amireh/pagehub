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
    'jquery.gridster':        'lib/jquery.gridster.min',
    'inflection': 'vendor/inflection',
    'md5': "vendor/md5",
    'timed_operation': "lib/timed_operation"
    // 'codemirror',             'vendor/'
  },

  shim: {
    'jquery': { exports: '$' },
    'jquery.ui': [ 'jquery' ],
    'jquery.util': [ 'jquery' ],
    'jquery.gridster': [ 'jquery' ],

    'shortcut': {
      exports: 'shortcut'
    },

    'pagehub': {
      deps: [ 'shortcut', 'jquery', 'jquery.ui', 'jquery.util', 'shortcut', 'modernizr' ],
      exports: 'UI'
    },

    'timed_operation': { deps: [ "underscore", "backbone" ], exports: 'timed_operation' },

    'underscore': {
      exports: '_'
    },

    'underscore.inflection': [ 'underscore' ],

    'inflection': [],
    'md5': [],

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
  'underscore',
  'jquery',
  'pagehub',
  'models/state',
  'underscore.helpers',
  'handlebars',
  'handlebars.helpers',
  'jquery.ui',
  'inflection',
  'md5',
  'shortcut'
], function(_, $, PageHub, State) {
  $.ajaxSetup({
    headers: {
      Accept : "application/json; charset=utf-8",
      "Content-Type": "application/json; charset=utf-8"
    }
  });

  var application = new State({});

  if (!pagehub_hooks)
    pagehub_hooks = [];

  console.log("PageHub dependencies loaded. Running " + pagehub_hooks.length + " hooks.")
  _.each(pagehub_hooks, function(cb) { cb(application); });
});

