define('views/spaces/page_actionbar',
[ 'backbone', 'hb!move_folder_link.hbs', 'hb!dialogs/destroy_page.hbs', 'shortcut', 'pagehub' ],
function(Backbone, MoveFolderLinkTemplate, DestroyPageTmpl, Shortcut, UI) {
  return Backbone.View.extend({
    el: $("#page_actions"),
    
    events: {
      'click a.save_page': 'save_page',
      'click a#destroy_page': 'destroy_page',
      'click a#edit_page': 'edit_page'
    },
    
    MovementListing: Backbone.View.extend({
      el: $("#movement_listing"),
      
      events: {
        'click a': 'move_page'
      },
      
      initialize: function(data) {
        this.space = data.space;
        this.ctx   = data.ctx;
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
        var el        = $(e.target),
            folder_id = el.attr("data-folder"),
            folder    = this.space.folders.get(parseInt(folder_id));
        
        if (!folder) {
          UI.report_error("Attempting to move page into a non-existent folder with id" + folder_id);
          return false;
        }
        
        var page        = this.ctx.current_page,
            old_folder  = page.folder;
        
        page.save({ folder_id: folder.get('id') }, {
          patch: true,
          success: function() {
            old_folder.pages.remove(page);
            folder.pages.add(page);
          }
        });
        
        e.preventDefault();
      }
    }),
    
    _ctx: {
      disabled:     false
    },
    
    initialize: function(data) {
      this.space  = data.space;
      this.editor = data.editor;
      this.ctx    = data.ctx;
      this.movement_listing = new this.MovementListing(data);      
      this.space.on('page_loaded', this.on_page_loaded, this);
      this.space.on('reset',       this.reset, this);
      
      this.anchors = {
        preview: this.$el.find('#preview'),
        edit:    this.$el.find('#edit_page'),
        destroy: this.$el.find('#destroy_page')
      };      
    
      
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
    
    disable: function() {
      this.$el.attr("disabled", "disabled").addClass("disabled");
      this._ctx.disabled = true;
      // this.undelegateEvents(); // this doesn't seem to work
    },
    
    enable: function() {
      this.$el.attr("disabled", null).removeClass("disabled");
      this._ctx.disabled = false;
      // this.delegateEvents();
    },
    
    on_page_loaded: function(page) {
      this.enable();
      this.anchors.preview.attr("href", page.get('media').href);
    },
    
    save_page: function() {
      if (this._ctx.disabled) { return false; }
      
      this.editor.serialize();
      var p = this.ctx.current_page;
      // console.log("saving page + " + JSON.stringify(this.ctx.current_page.toJSON()))
      p.save({ content: p.get('content')}, {
        patch: true,
        success: function() {
          UI.status.show("Page updated!", "good");
        }
      });
    },
    
    preview_page: function() {
      if (this._ctx.disabled) { return false; }
      
      window.open(this.ctx.current_page.get('media').href, "_preview")
    },

    destroy_page: function() {
      if (this._ctx.disabled) { return false; }

      var view  = this,
          page  = this.ctx.current_page,
          el    = DestroyPageTmpl(page.toJSON());

      var dialog = $(el).dialog({
        title: "Page removal",
        buttons: {
          Cancel: function() {
            dialog.dialog("close");
          },
          Remove: function(e) {
            page.destroy();
            dialog.dialog("close");
            e.preventDefault();
          }
        }
      });
    }, //destroy_page
    
    edit_page: function(evt) {
      var el      = $(evt.target),
          page    = this.ctx.current_page,
          space   = this.space;
      
      $.ajax({
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
                  patch: true
                });
                
                dialog.dialog("close");
                e.preventDefault();
              }
            }            
          });
        }
      });
    } // edit_page
  })
})