define('views/spaces/resource_actions',
[ 'backbone' ],
function(Backbone) {
  return Backbone.View.extend({
    el: $("#pages .actions"),
    
    events: {
      'click #new_page':   'create_page',
      'click #new_folder': 'create_folder'
    },
    
    initialize: function(data) {
      this.space = data.space;
      this.ctx   = data.ctx;
      this.$el.find('#new_page').attr("href", this.space.get('media').pages.url + '/new');
    },
    
    create_page: function(e) {
      e.preventDefault();
      
      ui.status.show("Creating a new page...", "pending");
      var folder  = this.ctx.current_folder || this.space.root_folder(),
          page    = folder.pages.add({});
      
      // this.space.trigger('load_page', page);
      
      return false;
    },
    
    create_folder: function(e) {
      e.preventDefault();
      
      ui.status.show("Creating a new folder...", "pending");
      
      var parent  = this.ctx.current_folder || this.space.root_folder();
      
      // this.space.trigger('load_page', page);
      
      return false;
    }
    
  })
})