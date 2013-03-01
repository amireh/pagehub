define(
'views/spaces/settings/setting_view',
[ 'backbone', 'jquery' ],
function(Backbone, $) {
  return Backbone.View.extend({
    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx;
    },

    render: function() {
      // if (this.director)
        // this.director.$el.show();

      this.$el.show("blind");
      return this;
    },

    hide: function() {
      this.$el.hide("blind");
    },

    serialize: function() {
      return {};
    },

    propagate_sync: function() {
      return this.director.save();
      // return this.main_view.update();
    }
  });
});