define(
'views/users/settings/profile',
[ 'views/shared/settings/setting_view', 'jquery', 'pagehub', 'hbs!templates/users/settings/profile_gravatar' ],
function(SettingView, $, UI, GravatarTmpl) {
  return SettingView.extend({
    el: $("#user_profile_settings"),

    templates: {
      avatar: GravatarTmpl
    },

    events: {
      'click [data-role=save]': 'propagate_sync'
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.elements = {
        avatar: this.$el.find('#avatar')
      }

      this.model.on('change', this.render_avatar, this);
      this.render_avatar();
    },

    render_avatar: function() {
      var user_data = this.model.toJSON();

      if (!user_data.gravatar_email)
        user_data.gravatar_email = user_data.email;

      this.elements.avatar.html(this.templates.avatar(user_data));

      return this;
    },

    serialize: function() {
      return this.$el.serializeObject();
    }
  });
});