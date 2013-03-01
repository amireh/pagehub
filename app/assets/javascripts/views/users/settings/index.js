define(
'views/users/settings/index',
[
  'views/shared/settings/director',
  'jquery',
  'pagehub',
  'shortcut',
  'views/users/settings/router',
  'views/users/settings/profile'
],
function(Director, $, UI, Shortcut, Router, ProfileView) {

  var UserSettingsView = Director.extend({
    // el: $("#space_settings"),

    initialize: function(data) {
      Director.prototype.initialize.apply(this, arguments);

      var view    = this;
      this.nav    = $('.settings nav');
      this.label  = 'settings';

      this.set_router(Router, 'profile');

      this.register(ProfileView, 'profile');

      Shortcut.add("ctrl+alt+s", function() { view.ctx.current_director.save(); });

      _.each(this.views, function(view) { view.$el.hide(); return true; });

      this.go('/' + this.model.get('media.url') + '/edit/');
    },

    hide: function() {
      this.current_view = null;
      return this;
    }

  });

  return UserSettingsView;
});