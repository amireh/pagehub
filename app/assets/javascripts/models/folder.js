define('models/folder',
  [ 'jquery', 'underscore', 'backbone', 'collections/pages', 'backbone.nested' ],
  function($, _, Backbone, Pages) {

var moo = false;
  var Folder = Backbone.DeepModel.extend({
    defaults: {
      title:        "",
      pretty_title: "",
    },

    initialize: function(data) {
      this.ctx      = {};
      this.urlRoot  = this.collection.space.get('media.folders.url');

      this.pages = new Pages({}, { folder: this, space: this.collection.space });
      this.pages.reset(data.pages);

      this.on('change:parent.id', this.configure_path, this);
      this.on('change:title', this.configure_path, this);
    },

    configure_path: function() {
      this.set('path', this.path());

      _.each(this.children(), function(f) {
        return f.configure_path();
      });

      return this;
    },

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

  });

  return Folder;
});