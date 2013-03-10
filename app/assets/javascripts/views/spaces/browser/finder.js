define('views/spaces/browser/finder',
[
  'jquery',
  'backbone',
  'views/spaces/browser/_impl',
  'views/spaces/browser/drag_manager',
  'views/spaces/browser/finder_navigator',
  'pagehub'
],
function( $, Backbone, BrowserImplementation, DragManager, FinderNavigator, UI) {

  return BrowserImplementation.extend({

    initialize: function(data) {
      var view = this;

      this.browser  = data.browser,
      this.ctx      = data.browser.ctx,
      this.space    = data.browser.space;

      // this.drag_manager = new DragManager(data);
      this.css_class    = 'finder-like';
      this.browser_type = 'finder';

      this.elements = {
        go_up:    $("#goto_parent_folder")
      }

      this.navigator = new FinderNavigator(data);
      this.drag_mgr  = new DragManager({ space: this.space, browser: this.browser });
      this.space.folders.on('change:parent.id', this.show_folder_if_applicable, this);
    },

    setup: function(ctx) {
      var view = this;

      this.$el.find('.folders, .pages, .folder-title').hide();

      if (ctx.current_folder) {
        this.on_folder_loaded(ctx.current_folder, null);
      }

      this.navigator.setup();

      return this;
    },

    cleanup: function() {
      var view = this;

      this.navigator.cleanup();

      this.$el
        .find('.folder, .folders, .pages, .folder-title').show().end()
        .find('.general-folder > .folder-title').hide();

      this.elements.go_up.hide();

      return this;
    },

    on_folder_rendered: function(f) {
      if (f != this.ctx.current_folder) { f.ctx.browser.empty_label.hide(); }
    },

    on_folder_loaded: function(f, last_folder) {
      this.$el.find('.folders, .pages, .folder-title').hide();

      var li      = f.ctx.browser.el,
          folders = f.ctx.browser.folder_listing,
          pages   = f.ctx.browser.page_listing,
          title   = f.ctx.browser.title;

      title.hide();

      // if this isn't the root folder, point our ".." link to the parent
      if (f.has_parent()) {
        this.elements.go_up
          .attr('data-folder', f.get_parent().get('id'))
          .find('a')
          .attr('href', '#' + f.get_parent().path())
          .end()
          .show()
          .children().show();

        folders.prepend(this.elements.go_up);
      }

      // show our ancestor elements, in order to show ourselves later
      li.hide().parents('.folder > .folders').show();

      // show our direct sub-folders
      folders.show()
      .find('> .folder').show()
      .find('> .folder-title').show().end()
      .find('.pages').hide(); // hide their pages

      // our pages
      pages.show();

      // now show ourselves, in order to be properly animated
      li.show("drop", {}, 250);

      return true;
    },

    dehighlight_folder: function() {
      this.$el.find(".folders .selected").removeClass('selected');

      return false;
    },

    highlight_folder: function(folder) {
      if (!folder) {
        return UI.report_error("Unable to highlight folder.");
      } else if (!folder.ctx) {
        return UI.report_error("Unable to highlight folder#" + folder.get('id') + ", bad context: " + JSON.stringify(folder.ctx));
      }

      this.dehighlight_folder();

      if (!folder.ctx.browser.title.is(":visible") &&
          this.elements.go_up.attr('data-folder') == folder.get('id')) {

        this.elements.go_up.find('a').addClass('selected');
      } else {
        folder.ctx.browser.title.addClass('selected');
      }

      return this;
    },

    show_folder_if_applicable: function(folder) {
      if (!folder.has_parent() || !folder.ctx.browser || !this.ctx.current_folder) {
        return true;
      }

      var is_visible = folder.get_parent() == this.ctx.current_folder;

      folder.ctx.browser.el.toggle(is_visible).parents('.folder > .folder-title0');
    }
  });
});