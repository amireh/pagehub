define('views/spaces/browser/_impl',
[
  'backbone'
],
function( Backbone ) {

  return Backbone.View.extend({
    el: $("#browser"),

    highlight_folder: function() {},
    dehighlight_folder: function() { this.$el.find('.folders .selected').removeClass('selected'); },

    // mark active page
    highlight_page: function()   {},
    // unmark active page (called on reset)
    dehighlight_page: function() { this.$el.find('.pages .selected').removeClass('selected'); },

    on_folder_loaded: function(folder, last_folder) {
    },

    on_folder_rendered: function(folder) {},
    on_page_rendered:   function(page) {},

    place_folder: function(folder) {},
    place_page: function(page) {},

    render: function(ctx) {
      this.setup(ctx);

      this.$el.add(this.$el.parent()).addClass(this.css_class);
    },
    setup: function(ctx) {},

    reset: function() {
      this.cleanup();
      this.$el.add(this.$el.parent()).removeClass(this.css_class);
    },
    cleanup: function() {},
  });
});