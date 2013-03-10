define('collections/pages',
[ 'jquery', 'backbone', 'models/page' ],
function($, Backbone, Page) {
  return Backbone.Collection.extend({
    model: Page,

    url:   function() {
      this.space.get('media').pages_url
    },

    // parse: function(data) {
    //   return data.folders;
    // },

    initialize: function(models, data) {
      _.implode(this, data);

      this.on('add', this.attach_to_folder, this);
      this.on('add', this.configure_path, this);
      this.on('change:folder.id', this.configure_path, this);
      this.folder.on('change:parent.id', this.configure_page_paths, this);
    },

    attach_to_folder: function(page) {
      page.folder = this.folder;
      // page.set('folder', this.folder);
      // page.set('folder_id', this.folder.get('id'));
    },

    configure_path: function(page) {
      page.set('path', page.path());
      return this;
    },

    configure_page_paths: function() {
      this.every(function(p) { return this.configure_path(p); }, this);
      return this;
    },

    // reset: function(data) {
    //   console.log("\tfolder page collection reset with " + data.length)
    //   return Backbone.Collection.prototype.reset.apply(this, data);
    // },
    // reset: function(models, options) {
    //   var out = Backbone.Collection.prototype.reset.apply(this, models, options);
    //   var self = this;

    //   // console.log(models)
    //   // _.each(models, function(page) {
    //   //   page.folder = self.folder;
    //   //   page.space  = self.folder.get('space');
    //   // });

    //   console.log(this.models)
    //   return out;
    // },

    // add: function(models, options) {
      // var self = this;
      // var out = Backbone.Collection.prototype.add.apply(this, models, options);

    //   console.log("adding " + JSON.stringify(models))

      // return out;
    // }
  });
})