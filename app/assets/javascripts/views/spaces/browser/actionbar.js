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
      'click #delete_folder': 'delete_folder',
      'click #show_browser_settings': 'show_settings'
    },

    initialize: function(data) {
      this.browser    = data.browser;
      this.ctx        = data.browser.ctx;
      this.space      = data.browser.space;
      this.workspace  = data.browser.workspace;

      this.elements = {
        edit_folder:   $("#edit_folder"),
        delete_folder: $("#delete_folder")
      };

      this.workspace.space.on('reset',            this.disable, this);
      this.workspace.space.on('folder_loaded',    this.enable, this);
      this.browser.on('folder_selected',  this.enable, this);
      this.browser.on('page_selected',    this.disable, this);
      // this.space.on('page_loaded',      this.enable, this);
    },

    __toggle: function(flag) {
      this.elements.edit_folder.prop('disabled', flag);
      this.elements.delete_folder.prop('disabled', flag);

      $("body > .tooltip").remove();

      return this;
    },

    enable: function(f) {
      var f = f || this.ctx.selected_folder || this.workspace.current_folder;
      console.log('[browser:actionbar] -- enabling for folder ' + f.get('title') + '-- ')

      if (!f.has_parent || !f.has_parent()) {
        return this.disable();
      }
      if (f && f.ctx.browser.el.hasClass('general-folder')) {
        return this.disable();
      }
      else if (f && f.ctx.browser.el.hasClass('goto-parent-folder')) {
        return this.disable();
      }

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
          folder  = this.ctx.selected_folder || this.workspace.current_folder,
          space   = this.space;

      if (!folder || !folder.has_parent()) {
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
    },

    show_settings: function() {
      return this.browser.settings.render();
    }

  });
});