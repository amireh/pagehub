define('views/spaces/resource_actions',
[ 'backbone', 'models/folder' ],
function(Backbone, Folder) {
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
      
      // ui.status.show("Creating a new folder...", "pending");
      
      var parent  = this.ctx.current_folder || this.space.root_folder(),
          space   = parent.collection.space;
          
      console.log(parent);
      
      $.ajax({
        type:   "GET",
        accept: "text/html",
        url:    space.get('media').folders.url + '/new',
        success: function(dialog_html) {
          $("body").append(dialog_html);
          var dialog = $("#new_folder_dialog").dialog();
          
          dialog.find('form').on('submit', function(e) {
            var folder_data = $(this).serializeObject();
            parent.space.folders.add(folder_data, { silent: true });
            var folder = _.last(parent.space.folders.models);
            console.log(folder)
            // if (folder.save(folder.toJSON(), { wait: true })) {
              // parent.space.folders.add(folder_data);
            // }
            e.preventDefault();
          });
          
          dialog.find('button.cancel').on('click', function(e) {
            e.preventDefault();
            dialog.dialog("close");
          });
        }
      });
      
      return false;
    }
    
  })
})