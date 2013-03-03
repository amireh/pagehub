define('views/spaces/browser',
[
  'jquery',
  'backbone',
  'views/spaces/browser/drag_manager',
  'hb!browser/folder.hbs',
  'hb!browser/page.hbs',
  'hb!dialogs/destroy_folder.hbs',
  'pagehub'
],
function( $, Backbone, DragManager, FolderTemplate, PageTemplate, DestroyFolderTmpl, UI ) {

  var init_collapsed_setting = function(object) {
    if (!get_collapsed_setting(object)) {
      object.state.user.set('preferences.runtime.spaces.' + object.state.space.get('id'), { collapsed: [] });
    }

    return true;
  },
      get_collapsed_setting = function(object) {
    return object.state.user.get('preferences.runtime.spaces.' + object.state.space.get('id') + '.collapsed');
  },  set_collapsed_setting = function(object, value) {
    return object.state.user.set('preferences.runtime.spaces.' + object.state.space.get('id') + '.collapsed', value);
  }

  return Backbone.View.extend({
    el: $("#browser"),

    templates: {
      folder: FolderTemplate,
      page:   PageTemplate
    },

    events: {
      'click li a': 'load_page',
      'click .edit_folder': 'edit_folder',
      'click .delete_folder': 'delete_folder',
      'click button[data-collapse]': 'collapse',
      'click .folder_title': 'collapse',
      'mouseenter .folder_title': 'highlight_hierarchy',
      'mouseleave .folder_title': 'dehighlight_hierarchy'
    },

    initialize: function(data) {
      _.implode(this, data);

      this.offset = 135;

      var view = this;
      $(window).on('resize', function() { return view.resize(); });

      this.space.on('load_page',    this.fetch_page, this);
      this.space.on('page_loaded',  this.highlight, this);
      this.space.on('page_loaded',  this.focus, this);
      this.space.on('page_created', this.on_page_loaded, this);
      this.space.on('reset', this.reset, this);
      this.space.folders.on('add', this.render_folder, this);
      this.space.folders.on('remove', this.remove_folder, this);
      this.space.folders.on('change:title', this.update_title, this);
      this.space.folders.on('change:title', this.reorder_folder, this);
      this.space.folders.on('change:parent.id', this.reorder_folder, this);
      // this.space.folders.on('sync', this.reorder_folder, this);

      this.drag_manager = new DragManager(data);

      init_collapsed_setting(this);

      this.elements = {
        scroller: $("#browser_scroller")
      }

      this.bootstrap();
    },

    bootstrap: function() {
      this.resize();

      console.log("Rendering " + this.space.folders.models.length + " folders");

      this.space.folders.every(function(f) {
        this.space.folders.trigger('add', f);
        f.pages.on('add', this.reorder_page, this);
        return true;
      }, this);

      this.space.folders.every(function(f) {
        this.space.folders.trigger('change:parent.id', f);
        return true;
      }, this);

      return this;
    },

    reset: function() {
      this.$el.find('.selected').removeClass('selected');
    },

    resize: function() {
      $("#pages .scroller").css("max-height", $(window).height() - 135);
    },

    render_folder: function(f) {
      var folder_data = $.extend(f.toJSON(), { is_general: !f.has_parent() }),
          entry   = this.templates.folder(folder_data),
          target  = this.$el,
          el      = target.append( entry ).children().last();

      f.ctx.browser = {
        el:             el,
        title:          el.find('.folder_title > span'),
        folder_listing: el.find('ol.folders'),
        collapser:      el.find('button[data-collapse]'),
        page_listing:   el.find('ol.pages'),
        empty_label:    el.find('.empty_folder')
      };

      if (!f.has_parent()) {
        f.ctx.browser.el.addClass('general-folder');
      }

      f.pages.on('add',           this.render_page, this);
      f.pages.on('remove',        this.remove_page, this);
      f.pages.on('sync',          this.on_page_loaded, this);
      f.pages.on('change:title',  this.update_title, this);
      f.pages.on('change:title',  this.reorder_page, this);
      f.pages.every(function(p) {
        return this.pages.trigger('add', p);
      }, f);

      f.trigger('change:parent.id', f);

      // if (this.ctx.settings.runtime.collapsed.indexOf(parseInt( f.get('id') )) != -1) {
      if (get_collapsed_setting(this).indexOf(parseInt( f.get('id') )) != -1) {
        this.__collapse(f.ctx.browser.collapser);
      }

      return this;
    },

    remove_folder: function(folder) {
      folder.ctx.browser.el.remove();

      if (this.ctx.current_folder == folder) {
        this.ctx.current_folder = null;
        this.ctx.current_page = null;
        this.space.trigger('reset');
      }
    },

    update_title: function(r) {
      r.ctx.browser.title.html(_.escape(r.get('title')))
    },

    reorder_folder: function(f) {

      if (f.ctx.browser && f.has_parent()) {
        var parent = f.get_parent();

        if (parent.ctx.browser) {

          var length = f.get('title').length,
              position =
                _.sortedIndex(
                  _.collect(parent.children(),
                    (function(p) { return p.get('title').toUpperCase() })),
                    f.get('title').toUpperCase()),
              listing  = parent.ctx.browser.folder_listing,
              el       = f.ctx.browser.el;

          // console.log("positioning folder " + f.get('title') + ' -> ' + position + ' [' + listing.children().length + ']');

          if (position == 0) {
            listing.prepend(el);
          } else if (position >= listing.children().length) {
            listing.append(el)
          } else {
            $(listing.children()[position-1]).after(el);
          }
        }
      }
    },

    render_page: function(page) {
      var folder  = page.folder,
          el      = folder.ctx.browser.page_listing.
                    append(this.templates.page(page.toJSON())).children().last();

      folder.ctx.browser.empty_label.hide();

      page.ctx.browser = {
        el:     el,
        anchor: el.find('a'),
        title:  el.find('a')
      }

      if (page.isNew()) {
        page.save();
      }

      return this;
    },

    remove_page: function(page) {
      page.ctx.browser.el.remove();

      // is the last folder empty now?
      if (page.collection.folder.pages.length == 0) {
        page.collection.folder.ctx.browser.empty_label.show();
      }

      if (this.ctx.current_page == page) {
        this.ctx.current_page = null;
        this.space.trigger('reset', page);
      }
    },

    highlight: function(page) {
      if (!page) { page = this.ctx.current_page; }
      this.reset();
      page.ctx.browser.el.addClass('selected');
      page.folder.ctx.browser.title.addClass('selected');
    },

    focus: function(page) {
      this.elements.scroller.scrollTop(page.ctx.browser.el.position().top);

      return this;
    },

    load_page: function(e) {
      var a         = $(e.target),
          page_id   = parseInt(a.attr("id").replace('page_', '')),
          folder_id = parseInt(a.parents(".folder:first").attr("id").replace('folder_', '')),
          folder    = this.space.folders.get(folder_id),
          page      = folder.pages.get(page_id);

      e.preventDefault();

      if (!page) {
        UI.report_error("unable to load page " + page_id + "!")
        return false;
      }

      this.space.trigger('load_page', page);

      return false;
    },

    fetch_page: function(page) {
      page.fetch();
    },

    on_page_loaded: function(page) {
      this.ctx.current_page   = page;
      this.ctx.current_folder = page.folder;
      page.folder.collection.space.trigger('page_loaded', page);
    },

    reorder_page: function(page) {
      var page_titles = _.collect(
                          _.reject(page.collection.pluck("title"),
                            function(s) { return s == page.get('title') }),
                          function(s) { return s.toUpperCase() }),
          position =  _.sortedIndex(page_titles, page.get('title').toUpperCase()),
          listing  = page.folder.ctx.browser.page_listing,
          el       = page.ctx.browser.el;

      el.hide();

      // console.log("positioning page " + page.get('title') + ' -> ' + position + ' [' + listing.children(":visible").length + ']');

      if (position == 0) {
        listing.prepend(el);
      } else if (position == listing.children(":visible").length) {
        listing.append(el)
      } else {
        $(listing.children(":visible")[position]).before(el);
      }

      el.show();
    },

    edit_folder: function(evt) {
      var el      = $(evt.target),
          folder  = this.space.folders.get( parseInt( el.parents(".folder:first").attr("id").replace('folder_', ''))),
          space   = this.space;

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
          folder  = this.space.folders.get(parseInt($(evt.target).parents(".folder:first").attr("id").replace('folder_', ''))),
          data    = folder.toJSON();

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

    collapse: function(evt) {
      // var source = $(evt.target);
      var source = $(evt.target);

      if (source.attr("data-collapse") == null) {
        source = source.parents(".folder:first").find('[data-collapse]:first');
      }

      this.__collapse(source);
      var data = { preferences: { runtime: { spaces: {} } } };

      data.preferences.runtime.spaces[this.state.space.get('id')] = {
        collapsed: get_collapsed_setting(this)
      };

      this.state.trigger('sync_runtime_preferences', data);
    },

    __collapse: function(source) {
      var folder_id = parseInt(source.parent().attr("id").replace('folder_', ''));

      if (source.attr("data-collapsed")) {
        // source.parent().siblings().show();
        source.siblings(":not(span.folder_title)").show();
        var caption = source.attr("data-collapsed-caption");
        source.attr("data-collapsed-caption", source.html());
        source.attr("data-collapsed", null).html(caption);
        source.parent().removeClass("collapsed");

        set_collapsed_setting(this, get_collapsed_setting(this).pop_value(folder_id));
      } else {
        source.siblings(":not(span.folder_title)").hide();
        // source.parent().siblings().hide();
        var caption = source.attr("data-collapsed-caption");
        source.attr("data-collapsed-caption", source.html());
        source.attr("data-collapsed", true).html(caption);
        source.parent().addClass("collapsed");

        get_collapsed_setting(this).push(folder_id);
        // this.ctx.settings.runtime.collapsed.push(folder_id);
        // this.ctx.settings_changed = true;
      }
    },

    highlight_hierarchy: function(evt) {
      $(evt.target).
      addClass("highlighted").
      parents(".folder").find("> span.folder_title").addClass("highlighted");
    },

    dehighlight_hierarchy: function(evt) {
      this.$el.find('.highlighted').removeClass("highlighted");
    }

  });
});