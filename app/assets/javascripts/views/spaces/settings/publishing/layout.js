define(
'views/spaces/settings/publishing/layout',
[
  'backbone',
  'jquery',
  'pagehub',
  'views/shared/settings/setting_view'
],
function(Backbone, $, UI, SettingView) {
  return SettingView.extend({
    el: $("form#layout_settings"),

    events: {
      'change input': 'propagate_sync'
    },

    serialize: function() {
      return {
        layout: $.extend(true, {
          name: 'fluid',
          show_homepages_in_sidebar: false,
          show_breadcrumbs: false
        }, this.$el.serializeObject())
      };
    }
  });
});