define('models/folder',
  [ 'jquery', 'underscore', 'backbone', 'collections/pages', 'backbone.nested' ],
  function($, _, Backbone, Pages) {

  var Folder = Backbone.DeepModel.extend({
    defaults: {
      title:        "",
      pretty_title: "",
      parent: null
    },

    // urlRoot: function() {
    //   return '/spaces/' + this.collection.space.get('id') + '/folders';
    // },

    has_parent: function() {
      return !!(this.get('parent'))
    },

    get_parent: function() {
      if (this.has_parent())
        return this.collection.get(this.get('parent').id);
      else
        return null;
    },

    ancestors: function() {
      var ancestors = [ this ];
      if (this.has_parent()) {
        ancestors.push( this.get_parent().ancestors() );
      }

      return _.reject(_.uniq(_.flatten(ancestors)), function(f) { return f == null; });
    },

    children: function() {
      return this.collection.where({ 'parent.id': this.get('id') });
    },

    parse: function(data) {
      return data.folder;
    },

    path: function() {
      var parts =
        _.reject(_.collect(this.ancestors(), function(f) { return f.get('pretty_title'); }),
          function(t) { return t == 'none'; })
        .reverse();

      // parts.push(this.get('pretty_title'));

      return parts.join('/');
    },

    initialize: function(data) {
      this.ctx = {};

      this.urlRoot = this.collection.space.get('media.folders.url');

      this.pages = new Pages;
      this.pages.on('add', this.attach_to_folder, this);
      this.pages.folder = this;
      this.pages.space  = this.collection.space;
      this.pages.reset(data.pages);


      // data.pages.every(function(pdata) {
      //   return this.pages.add(pdata);
      // }, this);
    },

    attach_to_folder: function(page) {
      page.folder = this;
      // page.set_folder();
      page.set('folder_id', this.get('id'));
    }
  });

  return Folder;
});