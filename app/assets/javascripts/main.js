requirejs.config({
  baseUrl: '/assets/javascripts',
  paths: {
    'jquery':                 'vendor/jquery-1.9.1.min',
    'jquery.ui':              'vendor/jquery-ui/jquery-ui-1.10.1.custom.min',
    'jquery.tinysort':        'vendor/jquery.tinysort.min',
    'underscore':             'vendor/underscore-min',
    'underscore.inflection':  'vendor/underscore/underscore.inflection',
    'backbone':               'vendor/backbone-min',
    'backbone.nested':        'vendor/backbone/deep-model.min',
    'Handlebars':             'vendor/handlebars',
    'hbs':                    'vendor/hbs/hbs',
    'hbs/i18nprecompile':     'vendor/hbs/i18nprecompile',
    'modernizr':              'vendor/modernizr',
    'shortcut':               'vendor/shortcut',
    'bootstrap':              'vendor/bootstrap/bootstrap',
    'pagehub':                'lib/pagehub',
    'pagehub.config':         'config',
    'pagehub.state':          'state',
    'jquery.gridster':        'vendor/jquery/jquery.gridster.min',
    'inflection':             'vendor/inflection',
    'md5':                    "vendor/md5",
    'timed_operation':        "lib/timed_operation",
    'animable_view':          'views/shared/animable_view',
    'canvas-loader':          'vendor/heartcode-canvasloader-min',

    'codemirror': 'vendor/codemirror-compressed',
  },

  shim: {
    'jquery': { exports: '$' },
    'jquery.ui': [ 'jquery' ],
    'jquery.gridster': [ 'jquery' ],
    'jquery.tinysort': [ 'jquery' ],

    'canvas-loader': { exports: 'canvas-loader' },

    'timed_operation': { deps: [ "underscore", "backbone" ], exports: 'timed_operation' },

    'underscore': {
      exports: '_'
    },

    'underscore.inflection': [ 'underscore' ],

    'shortcut':    { exports: 'shortcut' },
    'inflection':  [],
    'md5':         [],

    'bootstrap': {
      deps: [ 'jquery' ]
    },

    'backbone': {
      deps: [ "underscore", "jquery" ],
      exports: "Backbone"
    },

    'backbone.nested': [ 'backbone' ],

    'Handlebars': { exports: 'Handlebars' },

    'codemirror': {
      exports: 'CodeMirror'
    }
  },

  hbs: {
    templateExtension: "",
    disableI18n: true,
    disableHelpers: true
  }
});

require([
  'pagehub.state',
  'pagehub',
  'pagehub.config',
  'underscore',
  'jquery',
  'jquery.ui',
  'jquery.tinysort',
  'Handlebars',
  'inflection',
  'md5',
  'shortcut',

  'codemirror',

  'models/folder',
  'models/page',
  'models/space',
  'models/user',
  'collections/folders',
  'collections/pages',
  'collections/spaces',
  'helpers/handlebars',
  'helpers/underscore',
  'helpers/jquery',
  'views/flash',
  'views/header',
  'views/shared/animable_view',
  'views/shared/settings/director',
  'views/shared/settings/nav',
  'views/shared/settings/setting_view',
  'views/spaces/show',
  'views/spaces/new',
  'views/spaces/settings/index',
  'views/users/dashboard/director',
  'views/users/settings/index',
  'views/welcome/landing_page'

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

