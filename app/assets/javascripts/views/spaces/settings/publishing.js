define(
'views/spaces/settings/publishing',
[
  'backbone',
  'jquery',
  'pagehub',
  'shortcut',
  'views/spaces/settings/publishing/theme',
  'views/spaces/settings/publishing/layout',
  'views/spaces/settings/publishing/navigation_links',
  'views/spaces/settings/publishing/custom_css'
],
function(Backbone, $, UI, Shortcut, ThemeSettings, LayoutSettings, NavigationLinksSettings, CustomCSSSettings) {

  var SpacePublishingSettingsView = Backbone.View.extend({
    el: $("#space_publishing_settings"),

    events: {
      'click button': 'consume'
    },

    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx || {};
      this._ctx   = {};

      this.ctx.main_view = this;

      this.views = [
        new ThemeSettings(this.ctx),
        new LayoutSettings(this.ctx),
        new NavigationLinksSettings(this.ctx),
        new CustomCSSSettings(this.ctx)
      ];

      this.bootstrap();
    },

    bootstrap: function() {
      var view = this;
      Shortcut.add("ctrl+alt+s", function() { view.update(); });
      Shortcut.add("ctrl+alt+v", function() { window.open(view.space.get('media.href'), '_preview'); });
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    render: function(section) {
      _.each(this.views, function(view) {
        return view.render() || true;
      }, this);

      return this;
    },

    update: function() {
      var data = {},
          view = this;

      UI.status.mark_pending();

      _.each(this.views, function(view) {
        return data = $.extend(true, view.serialize(), data);
      }, this);

      this.space.save({ preferences: { publishing: data } }, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Preferences Saved!", "good");
        }
      });

      this.space.fetch({
        success: function() {
          view.render();
          UI.status.mark_ready();
        }
      });

      return this;
    }
  });

  return SpacePublishingSettingsView;
});