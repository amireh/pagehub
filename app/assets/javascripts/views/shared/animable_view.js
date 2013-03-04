define('animable_view', [ 'backbone', 'jquery', 'jquery.ui' ], function(Backbone, $) {
  return Backbone.View.extend({
    initialize: function(data) {
      _.implode(this, data);

      this.anime_length = 350;
    },

    animable: function() {
      return this.state && this.state.current_user && this.state.current_user.get('preferences.runtime.animations') == true;
    }
  })
})