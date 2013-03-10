define(
  'models/page',
  [ 'jquery', 'underscore', 'backbone', 'backbone.nested' ],
  function($, _, Backbone) {

  var Page = Backbone.DeepModel.extend({
    defaults: {
      title:        "",
      pretty_title: "",
      content:      "",
      creator:      null,
      revisions:    []
    },

    parse: function(data) {
      return data.page;
    },

    initialize: function() {
      this.ctx      = {};
      this.urlRoot  = this.collection.space.get('media.pages.url');

      if (this.get('title').length == 0) {
        this.set('title', 'Untitled#' + this.cid.toString().replace('c', ''));
      }

      this.on('change:folder.id', this.set_folder, this);
      // this.collection.on('add', this.set_folder, this);
    },

    // get_folder: function() {
    //   return this.collection.space.folders.get(this.get('folder.id'));
    // },

    set_folder: function() {
      console.log('folder changed!!!')
      // var space = this.collection.space,
      //     folder = space.folders.get(this.get('folder_id'));

      // this.folder = folder || space.root_folder();
    },

    path: function() {
      var parts = this.collection.folder.path().split('/');
      parts.push(this.get('pretty_title'));
      return parts.join('/');
    },

    fully_qualified_title: function() {
      var parts =
        _.reject(
          _.collect(this.collection.folder.ancestors(),
                    function(f) { return f.get('title'); }),
          function(t) { return t == 'None' })
        .reverse();

      parts.push(this.get('title'));

      return parts;
    }
  });

  return Page;
});