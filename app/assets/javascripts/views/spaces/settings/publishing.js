define(
'views/spaces/settings/publishing',
[
  'backbone',
  'jquery',
  'pagehub',
  'views/shared/settings/director',
  'views/spaces/settings/publishing/theme',
  'views/spaces/settings/publishing/layout',
  'views/spaces/settings/publishing/navigation_links',
  'views/spaces/settings/publishing/custom_css'
],
function(Backbone, $, UI, Director, ThemeSettings, LayoutSettings, NavigationLinksSettings, CustomCSSSettings) {

  var SpacePublishingSettingsView = Director.extend({
    el: $("#space_publishing_settings"),

    initialize: function(data) {
      Director.prototype.initialize.apply(this, arguments);

      this.add_alias('space');

      this.register(LayoutSettings,           'publishing/layout');
      this.register(ThemeSettings,            'publishing/theme');
      this.register(NavigationLinksSettings,  'publishing/navigation_links');
      this.register(CustomCSSSettings,        'publishing/custom_css');

      this.nav = $('.settings .subnav');
      this.bootstrap();
    },

    bootstrap: function() {
      _.each(this.views, function(view) { view.$el.hide(); return true; });
    },

    serialize: function() {
      return {
        preferences: {
          publishing: Director.prototype.serialize.apply(this)
        }
      };
    },

    hide: function() {
      this.current_view = null;
      _.each(this.views, function(v) { v.hide(); return true; });

      return this;
    }

  });

  return SpacePublishingSettingsView;
});