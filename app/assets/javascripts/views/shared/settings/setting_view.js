define(
'views/shared/settings/setting_view',
[ 'backbone', 'jquery' ],
function(Backbone, $) {
  return Backbone.View.extend({
    initialize: function(data) {
      // this.space  = data.space;
      // this.ctx    = data.ctx;
      var me = this;
      console.log(data)
      _.each(_.pairs(data), function(entry) { me[entry[0]] = entry[1]; });
      console.log(me)
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