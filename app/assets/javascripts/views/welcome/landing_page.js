define('views/welcome/landing_page',
[
  'backbone', 'jquery'
], function(Backbone, $) {
  return Backbone.View.extend({
    el: $("#landing_page"),

    events: {
    },

    initialize: function(app) {
      // this.$el.find("#feature_carousel");

      this.render();
    },

    render: function() {

      return this;
    },

  });
});