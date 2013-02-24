define('models/space',
  [ 'jquery', 'underscore', 'backbone', 'collections/folders' ],
  function($, _, Backbone, Folders) {
  var Space = Backbone.Model.extend({
    defaults: {
      title:        "",
      pretty_title: "",
      brief:        "",
      folders:      null,
      media: {
        url:  '',
        href: ''
      }
    },
    
    initialize: function(data) {
      var self = this;
      
      this.urlRoot = '/users/' + this.get('creator').id + '/spaces';
      
      this.folders = new Folders();
      this.folders.space = this;
      // this.folders.on('add', this.attach_to_space, this);
      
      _.each(data.folders, function(fdata) {
        self.folders.add(fdata);
      });
    },
    
    root_folder: function() {
      if (this.__root_folder) {
        return this.__root_folder;
      }
      
      this.__root_folder =
        _.select(this.folders.models, function(f) { return f.get('parent') == null; })[0];
        
      return this.__root_folder;
    }
  });
  
  return Space;
});