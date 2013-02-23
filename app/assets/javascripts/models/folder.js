define('models/folder',
  [ 'jquery', 'underscore', 'backbone', 'collections/pages' ],
  function($, _, Backbone, Pages) {
  
  var Folder = Backbone.Model.extend({
    defaults: {
      title:        "",
      pretty_title: "",
    },
    
    urlRoot: function() {
      return '/spaces/' + this.get('space').get('id') + '/folders';
    },
    
    initialize: function(data) {
      this.ctx = {};
      
      this.pages = new Pages;
      this.pages.on('add', this.attach_to_folder, this);
      this.pages.folder = this;
      this.pages.space  = this.collection.space;
      // this.pages.reset(data.pages);

      var self = this;
      _.each(data.pages, function(pdata) {
        self.pages.add(pdata);
      });
    },
    
    attach_to_folder: function(page) {
      page.folder = this;
      page.set('folder_id', this.get('id'));
    }
  });
  
  return Folder;
});