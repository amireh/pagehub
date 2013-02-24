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
    
    initialize: function(data) {
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