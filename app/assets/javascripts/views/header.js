define('views/header',
[
  'jquery'
], function($) {
  return Backbone.View.extend({
    el: $("#header"),

    initialize: function(app) {
      this.application = app;

      this.user = app.current_user;
      this.space = app.space;

      if (this.user) {
        this.user.on('change:nickname', this.update_path, this);
      }
    },

    update_path: function() {
      this.$el.find('#path > a:first').html(this.user.get('nickname'));
      this.$el.find('#cuser_settings_link').html(this.user.get('nickname'));
    }
  });
});