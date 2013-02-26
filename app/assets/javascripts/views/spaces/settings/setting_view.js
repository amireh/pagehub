define(
'views/spaces/settings/setting_view',
[ 'backbone', 'jquery' ],
function(Backbone, $) {
  return Backbone.View.extend({
    initialize: function(ctx) {
      this.main_view  = ctx.main_view;
      this.space      = this.main_view.space;
    },

    render: function() {
      return this;
    },

    serialize: function() {
      return {};
    },

    request_update: function() {
      return this.main_view.update();
    }
  });
});