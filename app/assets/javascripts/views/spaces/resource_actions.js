define('views/spaces/resource_actions',
[ 'backbone', 'models/folder', 'pagehub', 'shortcut' ],
function(Backbone, Folder, UI, Shortcut) {
  return Backbone.View.extend({
    el: $("#pages .actions"),
    
    events: {
      'click #new_page':   'create_page',
      'click #new_folder': 'create_folder'
    },
    
    initialize: function(data) {
      var view = this;
      
      this.space = data.space;
      this.ctx   = data.ctx;
      this.$el.find('#new_page').attr("href", this.space.get('media').pages.url + '/new');
      
      Shortcut.add("ctrl+alt+c", function() { view.create_page(); })
      Shortcut.add("ctrl+alt+f", function() { view.create_folder(); })
    },
    
    create_page: function(e) {
      if (e) { e.preventDefault(); }
      
      UI.status.show("Creating a new page...", "pending");
      var folder  = this.ctx.current_folder || this.space.root_folder(),
          page    = folder.pages.add({});
      
      // this.space.trigger('load_page', page);
      
      return false;
    },
    
    create_folder: function(e) {
      if (e) { e.preventDefault(); }
      
      // ui.status.show("Creating a new folder...", "pending");
      
      var parent  = this.ctx.current_folder || this.space.root_folder(),
          space   = parent.collection.space;
          
      
      $.ajax({
        type:   "GET",
        accept: "text/html",
        url:    space.get('media').folders.url + '/new',
        success: function(dialog_html) {
          var dialog = $("<div>" + dialog_html + "</div>").dialog({
            title: "Creating a folder",
            width: 'auto',
            buttons: {
              Cancel: function() {
                $(this).dialog("close");
              },
              Create: function(e) {
                var folder_data = dialog.find('form').serializeObject();
                space.folders.add(folder_data, { silent: true });
                // space.folders.add(folder_data);
                var folder = _.last(space.folders.models);
                console.log(folder)
                folder.save({}, {
                  wait: true,
                  success: function(f) {
                    f.collection.trigger('add', f);
                    dialog.dialog("close");
                  }
                });
                e.preventDefault();
                // $(this).dialog("close");
              }
            }
          });
          
          // dialog.find('form').on('submit', function(e) {
            
          // });
          
          // dialog.find('button.cancel').on('click', function(e) {
          //   e.preventDefault();
          //   dialog.dialog("close");
          // });
        }
      });
      
      return false;
    }
    
  })
})