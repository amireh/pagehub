define(
  'models/page',
  [ 'jquery', 'underscore', 'backbone'],
  function($, _, Backbone) {

  var Page = Backbone.Model.extend({
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
    // urlRoot: function() {
    //   return '/spaces/' + this.collection.space.get('id') + '/pages';
    // },

    initialize: function() {
      if (this.get('title').length == 0) {
        this.set('title', 'Untitled#' + this.cid.toString().replace('c', ''));
      }

      this.on('change:folder_id', this.set_folder, this);
      this.urlRoot = this.collection.space.get('media.pages.url');
      // this.collection.on('add', this.set_folder, this);
      this.ctx = {};
    },

    set_folder: function() {
      var space = this.collection.space,
          folder = space.folders.get(this.get('folder_id'));

      this.folder = folder || space.root_folder();
    },

    path: function() {
      var parts =
        _.reject(
          _.collect(this.folder.ancestors(),
                    function(f) { return f.get('pretty_title'); }),
          function(t) { return t == 'none' })
        .reverse();

      parts.push(this.get('pretty_title'));

      return parts.join('/');
    },

    fully_qualified_title: function() {
      var parts =
        _.reject(
          _.collect(this.folder.ancestors(),
                    function(f) { return f.get('title'); }),
          function(t) { return t == 'None' })
        .reverse();

      parts.push(this.get('title'));

      return parts;
    }
  });

  return Page;
});