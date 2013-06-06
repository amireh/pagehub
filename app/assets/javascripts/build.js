({
  appDir:   "./",
  baseUrl:  "./",
  dir:      "../compiled/javascripts",
  mainConfigFile: './main.js',
  optimize: "uglify",
  uglify: {
    toplevel:   true,
    ascii_only: true,
    beautify:   false,
    max_line_length: 1000,
    no_mangle: false
  },

  pragmasOnSave: {
      //removes Handlebars.Parser code (used to compile template strings) set
      //it to `false` if you need to parse template strings even after build
      excludeHbsParser : true,
      // kills the entire plugin set once it's built.
      excludeHbs: true,
      // removes i18n precompiler, handlebars and json2
      excludeAfterBuild: true
  },

  removeCombined: true,
  inlineText: true,
  preserveLicenseComments: false,

  modules: [
    {
      name: "main",
      include: [ 'main' ]
    }
  ]
})