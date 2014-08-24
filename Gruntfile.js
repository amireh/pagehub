var path = require('path');
var fs = require('fs');

module.exports = function(grunt) {
  'use strict';

  var jsRoot = path.join(__dirname, 'app', 'assets', 'javascripts');

  grunt.loadNpmTasks('grunt-contrib-requirejs');

  grunt.initConfig({
    requirejs: {
      compile: {
        options: {
          baseUrl:  "app/assets/javascripts",
          out: "public/js/compiled/app.js",
          mainConfigFile: 'app/assets/javascripts/main.js',
          optimize: "uglify",
          uglify: {
            toplevel:   true,
            ascii_only: true,
            beautify:   false,
            max_line_length: 1000,
            no_mangle: false
          },

          pragmasOnSave: {
            excludeHbsParser : true,
            excludeHbs: true,
            excludeAfterBuild: true
          },

          removeCombined: false,
          inlineText: true,
          preserveLicenseComments: false,

          name: "main",
          include: [ 'main' ]
        }
      }
    }
  });

  grunt.registerTask('development', function() {
    var compiledJsPath = path.join(__dirname, 'public', 'js', 'compiled', 'app.js');
    var rawJsPath = path.join(jsRoot, 'main.js');

    if (fs.existsSync(compiledJsPath)) {
      fs.unlinkSync(compiledJsPath);
    }

    fs.symlinkSync(rawJsPath, compiledJsPath);
  });
};
