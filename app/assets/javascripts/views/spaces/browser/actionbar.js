define('views/spaces/browser/actionbar',
[
  'jquery',
  'backbone',
  'hb!dialogs/destroy_folder.hbs',
  'pagehub'
],
function( $, Backbone, DestroyFolderTmpl, UI ) {

  return Backbone.View.extend({
    el: $("#browser_actionbar"),

    templates: {
      destroy_folder: DestroyFolderTmpl
    },

    events: {
      'click #edit_folder':   'edit_folder',
      'click #delete_folder': 'delete_folder'
    },

    initialize: function(data) {
      _.implode(this, data);

      this.elements = {
        edit_folder:   $("#edit_folder"),
        delete_folder: $("#delete_folder")
      };

      this.space.on('reset', this.disable, this);
      this.space.on('folder_selected', this.enable, this);
      // this.state.on('change:selected_folder', this.update, this);
    },

    __toggle: function(flag) {
      this.elements.edit_folder.prop('disabled', flag);
      this.elements.delete_folder.prop('disabled', flag);

      $("body > .tooltip").remove();

      return this;
    },

    enable: function() {
      return this.__toggle(false);
    },

    disable: function() {
      return this.__toggle(true);
    },

    reset: function() {
      return this.disable();
    },

    edit_folder: function(evt) {
      var el      = $(evt.target),
          folder  = this.ctx.selected_folder,
          space   = this.space;

      if (!folder) {
        return false;
      }

      $.ajax({
        type:   "GET",
        headers: { Accept: "text/html" },
        url:    folder.get('media').url + '/edit',
        success: function(dialog_html) {
          var dialog = $("<div>" + dialog_html + "</div>").dialog({
            title: "Folder properties",
            buttons: {
              Cancel: function() {
                $(this).dialog("close");
              },
              Update: function(e) {
                var folder_data = dialog.find('form').serializeObject();
                folder.save(folder_data, {
                  wait: true,
                  patch: true,
                  success: function() {
                    UI.status.show("Updated.", "good");
                    dialog.dialog("close");
                  }
                });
                e.preventDefault();
              }
            }
          });
        }
      });

      evt.preventDefault();
      return false;
    }, // edit_folder

    delete_folder: function(evt) {
      var view    = this,
          folder  = this.ctx.selected_folder,
          data    = folder.toJSON();

      if (!folder) {
        return false;
      }

      data.nr_pages     = folder.pages.length;
      data.nr_folders   = folder.children().length;
      data.nr_resources = data.nr_pages + data.nr_folders;

      var el      = DestroyFolderTmpl(data);

      $(el).dialog({
        title: "Folder removal",
        buttons: {
          Cancel: function() {
            $(this).dialog("close");
          },
          Remove: function() {
            folder.destroy({
              wait: true,
              success: function() {
                UI.status.show("Folder removed.", "good");
              }
            });
            $(this).dialog("close");
          }
        }
      });

      evt.preventDefault();
      return false;
    }

  });
});