define('views/spaces/browser/_impl',
[
  'backbone'
],
function( Backbone ) {

  return Backbone.View.extend({
    el: $("#browser"),

    highlight_folder: function(folder) {
      folder.ctx.browser.title.addClass('selected');
      return this;
    },

    highlight_current_folder: function(folder) {
      folder.ctx.browser.title.addClass('current');
      folder.ctx.browser.title.focus();
      return this;
    },

    dehighlight_folder: function() {
      this.$el.find('.folders .selected').removeClass('selected');
      return this;
    },

    dehighlight_current_folder: function() {
      this.$el.find('.folders .current').removeClass('current');
      return this;
    },

    // mark active page
    highlight_page: function(page) {
      page.ctx.browser.anchor.addClass('selected');
      return this;
    },

    highlight_current_page: function(page) {
      page.ctx.browser.anchor.addClass('current');
      page.ctx.browser.anchor.focus();
      return this;
    },

    // unmark selected page (called on reset highlights)
    dehighlight_page: function() {
      this.$el.find('.pages .selected').removeClass('selected');
      return this;
    },
    dehighlight_current_page: function() {
      this.$el.find('.pages .current').removeClass('current');
      return this;
    },

    on_folder_loaded: function(folder, last_folder) {},

    on_folder_rendered: function(folder) {},
    on_page_rendered:   function(page) {},

    place_folder: function(folder) {},
    place_page: function(page) {},

    render: function(ctx) {
      this.setup(ctx);
      this.$el.add(this.$el.parent()).addClass(this.css_class);

      return this;
    },

    setup: function(ctx) {},

    reset: function() {
      this.cleanup();
      this.$el.add(this.$el.parent()).removeClass(this.css_class);

      return this;
    },

    cleanup: function() {},
  });
});