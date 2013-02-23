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
    // jquery:     'lib/require-jquery',
    jquery:         'lib/jquery.min',
    underscore:     'lib/underscore-min',
    backbone:       'lib/backbone-min',
    text:           'lib/text',
    handlebars:     'lib/handlebars',
    hb:             'lib/hbtemplate'
  },

  shim: {
    underscore: {
      exports: '_'
    },
    backbone: {
      deps: ["underscore", "jquery" ],
      exports: "Backbone"
    },
    handlebars: {
      exports: 'Handlebars'
    }
  }
});

require([ 'app' ], function() { 

});

