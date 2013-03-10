define('views/spaces/page_actionbar',
[ 'animable_view', 'hb!move_folder_link.hbs', 'hb!dialogs/destroy_page.hbs', 'shortcut', 'pagehub', 'timed_operation' ],
function(AnimableView, MoveFolderLinkTemplate, DestroyPageTmpl, Shortcut, UI, TimedOp) {
  return AnimableView.extend({
    el: $("#page_actions"),

    events: {
      'click a#save_page': 'proxy_save_page',
      'click a#destroy_page': 'destroy_page',
      'click a#edit_page': 'proxy_edit_page'
    },

    MovementListing: Backbone.View.extend({
      el: $("#movement_listing"),

      events: {
        'click a': 'move_page'
      },

      initialize: function(data) {
        _.implode(this, data);

        this.space.folders.on('add',    this.add_link, this);
        this.space.folders.on('remove', this.rm_link, this);
      },

      add_link: function(folder) {
        var data = folder.toJSON();
        data.full_path =
          _.collect(
          _.reject(folder.ancestors(), function(f) { return f.get('title') == 'None' })
          .reverse(),
          function(f){ return f.get('title') }).join(' >> ');

        if (data.full_path.trim().length == 0)
          data.full_path = 'None';

        var link = MoveFolderLinkTemplate(data);

        this.$el.append("<li>" + link + "</li>");

        if (!folder.ctx) { folder.ctx = {} }
        if (!folder.ctx.page_actionbar) { folder.ctx.page_actionbar = {} }

        folder.ctx.page_actionbar.movement_anchor = this.$el.find('li:last');
      },

      rm_link: function(folder) {
        folder.ctx.page_actionbar.movement_anchor.remove();
      },

      render: function() {
        var self = this;
        _.each(this.space.folders.models, function(folder) {
          self.add_link(folder);
        })
      },

      move_page: function(e) {
        var view = this,
            el        = $(e.target),
            folder_id = el.attr("data-folder"),
            folder    = this.space.folders.get(parseInt(folder_id));

        if (!folder) {
          UI.report_error("Attempting to move page into a non-existent folder with id" + folder_id);
          return false;
        }

        var page        = this.workspace.current_page,
            old_folder  = page.folder;

        page.save({ folder_id: folder.get('id') }, {
          patch: true,
          wait: true,
          success: function() {
            // old_folder.pages.remove(page);
            // folder.pages.add(page);
            // view.space.trigger('reset');
            // view.space.trigger('load_page', page);
          }
        });

        e.preventDefault();
      }
    }),

    initialize: function(data) {
      AnimableView.prototype.initialize.apply(this, arguments);

      this.movement_listing = new this.MovementListing(data);
      this.workspace.on('page_loaded', this.on_page_loaded, this);
      this.workspace.on('current_page_updated', this.on_page_loaded, this);
      this.workspace.on('reset',       this.reset, this);

      this.disabled = false;
      this.anchors = {
        preview:    this.$el.find('#preview'),
        edit:       this.$el.find('#edit_page'),
        destroy:    this.$el.find('#destroy_page'),
        revisions:  this.$el.find('#revisions')
      };

      if (this.state.current_user.get("preferences.editing.autosave")) {
        console.log("Page content will be autosaved every " + (this.state.get('preferences.pulses.page_content') / 1000) + " seconds.");

        this.autosaver = new TimedOp(this, this.save_page, {
          pulse:     this.state.get('preferences.pulses.page_content'),
          with_flag: true,
          autoqueue: true
        });
      }

      this.state.on('hide_actionbar', this.hide, this);
      this.state.on('finder_hidden', this.show, this);
      this.bootstrap();
    },

    bootstrap: function() {
      var view = this;

      Shortcut.add("ctrl+alt+s", function() { view.save_page(); });
      Shortcut.add("ctrl+alt+v", function() { view.preview_page(); });
      Shortcut.add("ctrl+alt+d", function() { view.destroy_page(); });
      Shortcut.add("ctrl+alt+e", function() { view.anchors.edit.click(); });

      this.disable();
      this.movement_listing.render();
    },

    reset: function() {
      this.disable();
    },

    hide: function() {
      var view = this;

      if (this.animable()) {
        this.disable().$el.hide("slide", {}, this.anime_length, function() {
          view.state.trigger('actionbar_hidden');
        });
      } else {
        this.disable().$el.hide();
        view.state.trigger('actionbar_hidden');
      }

      return this;
    },

    show: function() {
      var view = this;

      if (this.animable()) {
        this.enable().$el.show("slide", {}, this.anime_length, function() {
          view.state.trigger('actionbar_shown');
        });
      } else {
        this.enable().$el.show();
        view.state.trigger('actionbar_shown');
      }

      return this;
    },

    disable: function() {
      this.$el.prop("disabled", true).addClass("disabled");
      this.disabled = true;

      this.autosaver && this.autosaver.stop();
      // this.undelegateEvents(); // this doesn't seem to work
      return this;
    },

    enable: function() {
      this.$el.prop("disabled", false).removeClass("disabled");
      this.disabled = false;

      this.autosaver && this.autosaver.start();
      // this.delegateEvents();

      return this;
    },

    on_page_loaded: function(page) {
      this.enable();
      this.anchors.preview.attr("href", page.get('media').href);
      this.anchors.revisions.attr("href", page.get('media').revisions.url);

      if (page.get('nr_revisions') == 1) {
        this.anchors.revisions.addClass('disabled').attr("href", null);
      } else {
        this.anchors.revisions.removeClass('disabled');
      }

    },

    proxy_save_page: function() {
      return this.save_page(false);
    },

    save_page: function(autosave) {
      if (this.disabled) { return false; }

      if (!this.editor.content_changed())
        return this;

      this.editor.serialize();
      var p = this.workspace.current_page;
      // console.log("saving page + " + JSON.stringify(this.workspace.current_page.toJSON()))
      p.save({ content: p.get('content'), no_object: true }, {
        patch: true,
        wait: true,
        success: function() {
          if (!autosave) {
            UI.status.show("Updated.", "good");
          }
        }
      });

      return this;
    },

    preview_page: function() {
      if (this.disabled) { return false; }

      window.open(this.workspace.current_page.get('media').href, "_preview")
    },

    destroy_page: function() {
      if (this.disabled) { return false; }

      var view  = this,
          page  = this.workspace.current_page,
          pages = this.workspace.current_page.collection,
          el    = DestroyPageTmpl(page.toJSON());

      var dialog = $(el).dialog({
        title: "Page removal",
        dialogClass: "warning",
        buttons: {
          Cancel: function() {
            dialog.dialog("close");
          },
          Remove: function() {
            page.destroy({
              wait: true,
              success: function(model, resp) {
                UI.status.show("Deleted.", "good");
                // pages.remove(page);
                dialog.dialog("close");
              }
            });
            // e.preventDefault();
          }
        }
      });
    }, //destroy_page

    proxy_edit_page: function(evt) {
      return this.edit_page(this.workspace.current_page);
    },

    edit_page: function(page) {
      if (this.disabled) { return false; }

      var view = this;

      $.ajax({
        headers: {
          Accept : "text/html; charset=utf-8",
          "Content-Type": "text/html; charset=utf-8"
        },
        type:   "GET",
        accept: "text/html",
        url:    page.get('media').url + '/edit',
        success: function(dialog_html) {
          var dialog = $("<div>" + dialog_html + "</div>").dialog({
            title: "Page properties",
            buttons: {
              Cancel: function() {
                $(this).dialog("close");
              },
              Update: function(e) {
                var data = dialog.find('form').serializeObject();

                page.save(data, {
                  wait: true,
                  patch: true,
                  success: function() {
                    UI.status.show("Updated.", "good");
                    // if (page == view.workspace.current_page) {
                    //   view.space.trigger('current_page_updated', page);
                    // }
                    console.log(page.toJSON());

                    dialog.dialog("close");
                  }
                });

                e.preventDefault();
              }
            }
          });
        }
      });
    } // edit_page
  })
})