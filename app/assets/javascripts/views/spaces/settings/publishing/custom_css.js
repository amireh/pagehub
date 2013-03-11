define(
'views/spaces/settings/publishing/custom_css',
[
  'jquery',
  'views/shared/settings/setting_view',
  'views/spaces/editor'
],
function($, SettingView, Editor) {
  return SettingView.extend({
    el: $("form#custom_css_settings"),

    events: {
      'change input': 'propagate_sync'
    },

    initialize: function(ctx) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.editor = new Editor({
        space:  this.space,
        config: {
          el:   "#css_editor",
          mode: "css",
          offset: 230
        }
      });
    },

    render: function() {
      SettingView.prototype.render.apply(this, arguments);

      this.editor.reset().editor.setValue(this.space.get('preferences.publishing.custom_css') || '');
      return this;
    },

    serialize: function() {
      var data = this.editor.serialize();

      return {
        custom_css: data
      }
    }
  });
});