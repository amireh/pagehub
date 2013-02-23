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
    urlRoot: function() {
      return '/spaces/' + this.collection.space.get('id') + '/pages';
    },
    
    initialize: function() {
      if (this.get('title').length == 0) {
        this.set('title', 'Untitled#' + this.cid.toString().replace('c', ''));
      }
      
      this.ctx = {};
    }
  });
  
  return Page;
});