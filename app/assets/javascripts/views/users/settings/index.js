define(
'views/users/settings/index',
[
  'views/shared/settings/director',
  'jquery',
  'pagehub',
  'shortcut',
  'views/users/settings/router',
  'views/users/settings/profile',
  'views/users/settings/account',
  'views/users/settings/editing',
  'views/users/settings/spaces'
],
function(Director, $, UI, Shortcut, Router, ProfileView, AccountView, EditingView, SpacesView) {

  var saving_captions = { true: "Saving...", false: "Save" };
  var UserSettingsView = Director.extend({
    // el: $("#space_settings"),

    initialize: function(data) {
      Director.prototype.initialize.apply(this, arguments);

      var director      = this;
      this.label        = 'settings';
      this.nav          = $('.settings nav');
      this.save_button  = this.nav.find("button[data-role=save]");

      this
      .set_router(Router, 'profile')
      .add_alias('user')
      .register(ProfileView, 'profile')
      .register(AccountView, 'account')
      .register(EditingView, 'editing')
      .register(SpacesView, 'spaces');

      Shortcut.add("ctrl+alt+s", function() {
        // in case we use multiple directors in the future
        director.ctx.current_director.save();
      });

      this.save_button.on('click', function(e) {
        return director.ctx.current_director.save();
      });

      this.ctx.save_button = this.save_button;

      this.state.on('change:syncing', this.control_save_button, this);

      _.each(this.views, function(view) { view.$el.hide(); return true; });

      this.go('/edit');
    },

    hide: function() {
      this.current_view = null;
      return this;
    },

    control_save_button: function() {
      this.save_button
      .html(saving_captions[this.state.get('syncing')])
      .prop('disabled', this.state.get('syncing'));

      return this;
    }

  });

  return UserSettingsView;
});