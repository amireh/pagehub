define('views/spaces/resource_actions',
[ 'backbone', 'models/folder', 'pagehub', 'shortcut' ],
function(Backbone, Folder, UI, Shortcut) {
  return Backbone.View.extend({
    el: $("#pages .actions"),

    events: {
      'click #new_page':    'create_page',
      'click #new_folder':  'create_folder',
      'click #download_zip': 'download_space'
    },

    initialize: function(data) {
      var view = this;

      _.implode(this, data);

      this.$el.find('#new_page').attr("href", this.space.get('media').pages.url + '/new');

      Shortcut.add("ctrl+alt+c", function() { view.create_page(); })
      Shortcut.add("ctrl+alt+f", function() { view.create_folder(); })
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    create_page: function(e) {
      if (e) { e.preventDefault(); }

      // UI.status.show("Creating a new page...", "pending");
      var folder  = this.ctx.current_folder || this.space.root_folder();

      folder.pages.add({ folder_id: folder.get('id') }, { silent: true });
      var page = _.last(folder.pages.models);

      page.save({}, {
        success: function() {
          page.collection.trigger('add', page);
          UI.status.show("Created!", "good");
        }
      })
      // this.space.trigger('load_page', page);

      return false;
    },

    create_folder: function(e) {
      if (e) { e.preventDefault(); }

      // ui.status.show("Creating a new folder...", "pending");

      var parent  = this.ctx.current_folder || this.space.root_folder(),
          space   = parent.collection.space,
          view    = this;

      $.ajax({
        type:   "GET",
        headers: { Accept: "text/html" },
        url:    space.get('media').folders.url + '/new',
        success: function(dialog_html) {
          var dialog = $('<div>' + dialog_html + '</div>').dialog({
            title: "Creating a folder",
            width: 'auto',

            // select the current folder from the parent folder list for convenience
            open: function() {
              UI.dialog.on_open($(this));

              $(this)
              .find('select :selected').attr("selected", false).end()
              .find("select option[value=" + parent.get('id') + "]").attr("selected", true).end();

              return true;
            },

            buttons: {
              Cancel: function() {
                $(this).dialog("close");
              },
              Create: function(e) {
                var folder_data = dialog.find('form').serializeObject();
                space.folders.add(folder_data, { silent: true });
                var folder = _.last(space.folders.models);

                folder.save({}, {
                  wait: true,
                  success: function(f) {
                    UI.status.show("Folder created!", "good");
                    f.collection.trigger('add', f);
                    dialog.dialog("close");
                  }
                });
                e.preventDefault();
              }
            }
          });
        }
      });

      return false;
    },

    download_space: function(e) {
      UI.status.show('Please wait while we create the ZIP archive for you.', 'good');

      return true;
    }
  })
})