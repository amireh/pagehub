define('models/folder',
  [ 'jquery', 'underscore', 'backbone', 'collections/pages', 'backbone.nested' ],
  function($, _, Backbone, Pages) {
  
  var Folder = Backbone.DeepModel.extend({
    defaults: {
      title:        "",
      pretty_title: "",
      parent: null
    },
    
    urlRoot: function() {
      return '/spaces/' + this.collection.space.get('id') + '/folders';
    },
    
    has_parent: function() {
      return !!(this.get('parent'))
    },
    
    get_parent: function() {
      return this.collection.get(this.get('parent').id);
    },

    children: function() {
      return this.collection.space.folders.where({ 'parent.id': this.get('id') });
    },
    parse: function(data) {
      return data.folder;
    },
    
    initialize: function(data) {
      this.ctx = {};
      
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