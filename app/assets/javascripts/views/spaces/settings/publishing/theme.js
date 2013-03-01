define(
'views/spaces/settings/publishing/theme',
[
  'backbone',
  'jquery',
  'pagehub',
  'views/spaces/settings/setting_view'
],
function(Backbone, $, UI, SettingView) {
  return SettingView.extend({
    el: $("form#theme_settings"),

    events: {
      'change input': 'propagate_sync'
    },

    initialize: function(ctx) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.browser  = this.$el.find('#theme_browser');
      this.path = 'theme';
    },

    serialize: function() {
      return {
        theme: $.extend(true, {
          name: 'Clean'
        }, this.$el.serializeObject())
      };
    },

    // preview_theme: function(theme) {
    //   UI.status.mark_pending();
    //   this.browser.attr("src", this.space.get('media.url') + "/testdrive?theme=" + theme + '&embedded=true');
    //   UI.status.mark_ready();
    //   return this;
    // }
  });
});