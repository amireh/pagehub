define('views/spaces/browser/drag_manager',
[
  'jquery',
  'backbone',
  'pagehub'
],
function( $, Backbone, UI ) {
  return Backbone.View.extend({
    el: $("#browser"),

    events: {
    },

    initialize: function(data) {
      _.implode(this, data);

      // Make it draggable
      if (Modernizr.draganddrop) {
        this.space.folders.on('add', this.bind_folder_pages, this);
        this.space.on('move_folder', this.move_folder, this);
        this.space.on('move_page', this.move_page, this);
        this.space.on('folder_loaded', this.bind_go_to_parent_folder, this);
      } else {
        console.log("No dragndrop support, ignoring...");
      }

      this.bootstrap();
    },

    bootstrap: function() {
      this._ctx = {}
    },

    reset: function() {
      return this.abort_dnd();
    },

    abort_dnd: function() {
      this._ctx.is_dragging = false;
      this._ctx.source      = null;

      // $("#indicator").hide();
      // $("#drag_indicator").hide();

      this.$el.find(".drag-src,.drop-target").removeClass("drag-src drop-target");

      return false;
    },

    __bind: function(el) {
      _.each([ 'dragstart', 'dragenter', 'drop', 'dragend', 'dragleave', 'dragover' ],
             function(evt) { el.off(evt); });

      el.on('dragstart', this, this.start_dragging);
      el.on('dragenter', this, this.on_dragenter);
      el.on('drop',      this, this.on_drop);
      el.on('dragend',   this, this.on_drop);
      el.on('dragleave', this, this.consume_dragevent);
      el.on('dragover',  this, this.consume_dragevent);

      return this;
    },

    bind_folder_pages: function(folder) {
      // console.log("Enabling D&D for " + folder.pages.models.length + " pages in folder " + folder.get('title'))

      // folder.pages.every(function(page) {
      //   return this.bind_page(page);
      // }, this);

      this.__bind(folder.ctx.browser.anchor);
      folder.pages.on('add', this.bind_page, this);

      return this;
    },

    bind_page: function(page) {
      return this.__bind(page.ctx.browser.anchor);
    },

    bind_go_to_parent_folder: function(folder) {
      var el = folder.ctx.browser.folder_listing.find('#goto_parent_folder');
      if (!el) {
        console.log("[error] can not find go-to parent folder navigator");
        return false;
      }
      console.log("[drag mgr] binding go_up button")
      this.__bind(el.find('> .folder-title'));
    },

    consume_dragevent: function(e) {
      e.preventDefault();

      // e.dataTransfer.dropEffect = 'move';

      return false;
    },

    start_dragging: function(e, view) {
      var raw_e = e.originalEvent,
          el    = $(this),
          view  = e.data;

      view.reset();

      console.log(el)
      if (!el.is('[draggable]')) {
        return false;
      }
      else if (!el.parent().hasClass('page') && !el.parent().hasClass('folder')) {
        return false;
      }

      el.addClass("drag-src");

      // This is a necessary hack for Firefox to even accept the
      // component as being draggable (apparently draggable=true isn't enough)
      raw_e.dataTransfer.setData('ignore_me', 'fubar');

      view._ctx.is_dragging = true;
      view._ctx.source = el;

      return true;
    },

    on_dragenter: function(e) {
      var view = e.data,
          target = null;

      view.$el.find(".drop-target").removeClass("drop-target");

      // dropping is only allowed on folder targets
      // if((target = $(this).parents(".folder:first")).length != 0) {
      if($(this).is(":visible") && $(this).hasClass('folder-title')) {
        console.log("drag target located: ");
        console.log($(this))

        target = $(this);
        target.addClass('drop-target');
        view._ctx.target = target;
      }
      else {
        view._ctx.target = null;
        return false;
      }
    },

    on_drop: function(e) {
      var view = e.data;

      e.preventDefault();
      e.stopPropagation();

      // Since we bind to both 'dragend' and 'drop' events for browser compatibility
      // some browers might fire the callback twice, so we guard against it here.
      if (!view._ctx.is_dragging || !view._ctx.target) {
        return view.abort_dnd();
      }

      console.log(view._ctx.target);

      // var src_node = view.$el.find('.drag-src:first'),
      var src_node = view._ctx.source,
          tgt_node = view._ctx.target;

      if (!tgt_node.is(".folder-title")) {
        return view.abort_dnd();
      }

      // view._ctx.is_dragging = false;

      // dragging a folder?
      if (src_node.hasClass("folder-title")) {
        var source = view.browser.folder_from_title(src_node),
            target = view.browser.folder_from_title(tgt_node);

        if (source && target && source != target) {
          view.space.trigger('move_folder', {
            folder: source,
            parent: target
          });
        }

      } // folder drag

      // dragging a page?
      else {
        var target_folder = view.browser.folder_from_title(tgt_node),
            source_folder = view.browser.folder_from_title(src_node),
            page          = view.browser.page_from_title(src_node);

        if (page && source_folder && target_folder && source_folder != target_folder) {
          view.space.trigger('move_page', page, target_folder);
        }
      } // page drag

      // Unmark the nodes & cleanup
      return view.reset();
    }, // on_drop()

    move_folder: function(data) {
      if (!data.folder || !data.parent) {
        console.log("bad move folder evt!" + JSON.stringify(data))
        return false;
      }

      data.folder.save({ parent_id: data.parent.get('id') }, {
        patch: true,
        wait: true,
        success: function() {
          UI.status.show("Folder moved.", "good");
        }
      });
    },

    move_page: function(page, folder) {
      if (!page || !folder) {
        console.log("bad move page evt!" + JSON.stringify(data))
        return false;
      }

      var old_folder = page.folder;

      page.save({ folder_id: folder.get('id') }, {
        patch: true,
        wait:  true,
        success: function() {
          UI.status.show("Page moved.", "good");
          // old_folder.pages.remove(page);
          // folder.pages.add(page);
        }
      });
    }
  });
});