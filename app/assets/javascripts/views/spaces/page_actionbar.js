define('views/spaces/page_actionbar',
[ 'backbone', 'hb!move_folder_link.hbs' ],
function(Backbone, MoveFolderLinkTemplate) {
  return Backbone.View.extend({
    el: $("#page_actions"),
    
    events: {
      'click a.save_page': 'save_page'
    },
    
    MovementListing: Backbone.View.extend({
      el: $("#movement_listing"),
      initialize: function(data) {
        this.space = data.space;
        this.space.folders.on('add',    this.add_link, this);
        this.space.folders.on('remove', this.rm_link, this);
      },
      
      add_link: function(folder) {
        var link = MoveFolderLinkTemplate(folder.toJSON());
        this.$el.append("<li>" + link + "</li>");
      },
      
      rm_link: function(folder) {
      },
      
      render: function() {
        var self = this;
        _.each(this.space.folders.models, function(folder) {
          self.add_link(folder);
        })
      }
    }),
    
    _ctx: {
      disabled:     false,
      current_page: null
    },
    
    initialize: function(data) {
      this.space  = data.space;
      this.editor = data.editor;
      this.ctx    = data.ctx;
      this.movement_listing = new this.MovementListing(data);      
      this.space.on('page_loaded', this.on_page_loaded, this);
      
      this.anchors = {
        preview: this.$el.find('#preview')
      };      
    
      this.bootstrap();
    },
    
    bootstrap: function() {
      this.disable();
      this.movement_listing.render();
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
          ui.status.show("Page updated!", "good");
        }
      });
    }
  })
})