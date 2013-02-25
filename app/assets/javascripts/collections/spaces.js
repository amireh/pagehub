define('collections/spaces',
[ 'jquery', 'backbone', 'models/space' ],
function($, Backbone, Space) {
  return Backbone.Collection.extend({
    defaults: {
    },
    
    model: Space,
    
    url:   function() {
      this.creator.get('media').spaces_url
    },
    
    parse: function(data) {
      return data.spaces;
    },
    
    initialize: function() {
      this.creator = null;
    }
  });
})