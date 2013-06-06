({
  appDir: "./",
  baseUrl: "./",
  dir: "../compiled/javascripts",
  optimize: "none",

  pragmasOnSave: {
      //removes Handlebars.Parser code (used to compile template strings) set
      //it to `false` if you need to parse template strings even after build
      excludeHbsParser : true,
      // kills the entire plugin set once it's built.
      excludeHbs: true,
      // removes i18n precompiler, handlebars and json2
      excludeAfterBuild: true
  },

  inlineText: true,

  hbs: {
    templateExtension: "",
    disableI18n: true,
    disableHelpers: true
  },

  paths: {
    'jquery':                 'vendor/jquery-1.9.1.min',
    'jquery.ui':              'vendor/jquery-ui/jquery-ui-1.10.1.custom.min',
    'jquery.util':            'helpers/util',
    'jquery.tinysort':        'vendor/jquery.tinysort.min',
    'underscore':             'lib/underscore-min',
    'underscore.inflection':  'lib/underscore/underscore.inflection',
    'underscore.helpers':     'helpers/underscore',
    'backbone':               'lib/backbone-min',
    'backbone.nested':        'lib/backbone/deep-model.min',
    'text':                   'lib/text',
    'Handlebars':             'lib/handlebars',
    'handlebars.helpers':     'helpers/handlebars',
    'hbs':                    'vendor/hbs',
    'hbs/i18nprecompile':     'vendor/hbs/i18nprecompile',
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
    'canvas-loader':          'vendor/heartcode-canvasloader-min',
    'views/header':                   'views/header',

    'users.dashboard.bundle': 'views/users/dashboard.bundle'

    // 'views/spaces/page_actionbar': 'views/spaces/page_actionbar'
    // 'views/spaces/browser/finder_navigator': ''
    // 'views/spaces/browser/finder': ''
    // 'views/spaces/browser/drag_manager': ''
    // 'views/spaces/browser/actionbar': ''
    // 'views/spaces/browser/explorer': ''
    // 'views/spaces/browser/settings': ''
    // 'views/spaces/browser/_impl': ''
    // 'views/spaces/browser/browser': ''
    // 'views/spaces/workspace/router': ''
    // 'views/spaces/resource_actions': ''
    // 'views/spaces/settings/publishing/router': ''
    // 'views/spaces/settings/router': ''
    // 'views/flash': ''
    // 'views/welcome/landing_page': ''
    // 'handlebars.helpers': ''
    // 'underscore.helpers': ''
    // 'pagehub.config': ''
    // 'timed_operation': ''
    // 'pagehub': ''
    // 'pagehub.state': ''
    // 'models/user': ''
    // 'models/state': ''
    // 'models/folder': ''
    // 'models/space': ''
    // 'collections/pages': ''
    // 'collections/spaces': ''
    // 'collections/folders': ''
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

    'Handlebars': {
      exports: 'Handlebars'
    }
  },

  modules: [
    {
      name: "common",
      include: [ 'main' ]
    },
    {
      name: "users.dashboard.bundle",
      include: [ 'common', 'users.dashboard.bundle' ]
    }
  ]
})