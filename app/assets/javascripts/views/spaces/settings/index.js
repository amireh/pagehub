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

  var SpaceSettingsView = Director.extend({
    // el: $("#space_settings"),

    initialize: function(data) {
      Director.prototype.initialize.apply(this, arguments);

      this.register_alias('space');

      var view    = this;
      this.nav    = $('.settings nav');
      this.label  = 'settings';
      this.space  = this.model;

      this.set_router(Router, 'general');

      this.register(GeneralView,      'general');
      this.register(MembershipsView,  'memberships');
      this.register(PublishingView,   'publishing');
      this.register(BrowsabilityView, 'browsability');

      Shortcut.add("ctrl+alt+v", function() { window.open(view.space.get('media.href'), '_preview'); });
      Shortcut.add("ctrl+alt+s", function() { view.ctx.current_director.save(); });

      _.each(this.views, function(view) { view.$el.hide(); return true; });

      this.go('/' + this.space.get('media.url') + '/edit/');
    },

    hide: function() {
      this.current_view = null;
      return this;
    }

  });

  return SpaceSettingsView;
});