define(
'views/spaces/settings/index',
[
  'views/shared/settings/director',
  'jquery',
  'pagehub',
  'shortcut',
  'views/spaces/settings/router',
  'views/spaces/settings/general',
  'views/spaces/settings/memberships',
  'views/spaces/settings/publishing',
  'views/spaces/settings/browsability'
],
function(Director, $, UI, Shortcut, Router, GeneralView, MembershipsView, PublishingView, BrowsabilityView) {

  var saving_captions = { true: "Saving...", false: "Save" };
  var SpaceSettingsView = Director.extend({
    // el: $("#space_settings"),

    initialize: function(data) {
      Director.prototype.initialize.apply(this, arguments);

      this.add_alias('space');

      var director    = this;
      this.label  = 'settings';
      this.space  = this.model;
      this.nav    = $('.settings nav');
      this.save_button = this.nav.find("button[data-role=save]");

      this.set_router(Router, 'general');

      this.register(GeneralView,      'general');
      this.register(MembershipsView,  'memberships');
      this.register(PublishingView,   'publishing');
      this.register(BrowsabilityView, 'browsability');

      Shortcut.add("ctrl+alt+v", function() { window.open(director.space.get('media.href'), '_preview'); });
      Shortcut.add("ctrl+alt+s", function() { director.ctx.current_director.save(); });

      this.save_button.on('click', function(e) {
        return director.ctx.current_director.save();
      });

      this.state.on('change:syncing', this.control_save_button, this);

      this.ctx.save_button = this.save_button; // expose it for SettingView#mark_destructive_action

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

  return SpaceSettingsView;
});