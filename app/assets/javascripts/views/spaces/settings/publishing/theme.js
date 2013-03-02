define(
'views/spaces/settings/publishing/theme',
[
  'backbone',
  'jquery',
  'pagehub',
  'views/shared/settings/setting_view'
],
function(Backbone, $, UI, SettingView) {
  return SettingView.extend({
    el: $("form#theme_settings"),

    events: {
      'change input': 'propagate_sync'
    },

    serialize: function() {
      return {
        theme: $.extend(true, {
          name: 'Clean'
        }, this.$el.serializeObject())
      };
    }
  });
});