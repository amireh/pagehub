define('views/spaces/browser/finder',
[
  'jquery',
  'backbone',
  'views/spaces/browser/_impl',
  'views/spaces/browser/drag_manager',
  'pagehub'
],
function( $, Backbone, BrowserImplementation, DragManager, UI ) {

  return BrowserImplementation.extend({
    initialize: function(data) {
      // this.drag_manager = new DragManager(data);
      this.css_class = 'finder-like';
      this.browser_type = 'finder';

      this.elements = {
        go_up:    $("#goto_parent_folder")
      }
    },

    setup: function(ctx) {
      this.$el.find('.folders, .pages, .folder_title').hide();

      if (ctx.current_folder) {
        this.on_folder_loaded(ctx.current_folder, null);
      }
    },

    cleanup: function() {
      this.$el
        .find('.folders, .pages, .folder_title').show().end()
        .find('.general-folder > .folder_title').hide();

      this.elements.go_up.hide();
    },

    on_folder_loaded: function(f, last_folder) {
      this.$el.find('.folders, .pages, .folder_title').hide();

      var li      = f.ctx.browser.el,
          folders = f.ctx.browser.folder_listing,
          pages   = f.ctx.browser.page_listing,
          title   = f.ctx.browser.title_container;

      title.hide();

      // if this isn't the root folder, point our ".." link to the parent
      if (f.has_parent()) {
        this.elements.go_up
          .attr('data-folder', f.get_parent().get('id'))
          .find('a')
          .attr('data-href', f.get_parent().path())
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
      .find('> .folder_title').show().end()
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

    highlight_page: function(page) {
      // if (!page) { page = this.ctx.current_page; }

      // this.$el.find('.pages .selected').removeClass('selected');

      page.ctx.browser.el.addClass('selected');
      // return this.highlight_folder(page.folder, true);
      return true;
    }

  });
});