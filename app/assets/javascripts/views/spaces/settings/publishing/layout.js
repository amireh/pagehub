define(
'views/spaces/settings/publishing/layout',
[
  'backbone',
  'jquery',
  'pagehub',
  'views/spaces/settings/setting_view'
],
function(Backbone, $, UI, SettingView) {
  return SettingView.extend({
    el: $("form#layout_settings"),

    events: {
      'change input': 'request_update'
    },

    initialize: function(ctx) {
      SettingView.prototype.initialize.apply(this, arguments);
      this.path = 'layout';
    },

    // load: function(el) {
    //   var view = this;
    //   console.log("loading layout view")

    //   $.ajax({
    //     type: "GET",
    //     headers: { Accept: "text/html" },
    //     url:  this.space.get('media.url') + '/edit/publishing/layout',
    //     success: function(html) {
    //       el.html(html);
    //       view.$el = el;
    //       view.render();
    //     }
    //   })
    // },

    render: function() {
      this.$el.show();
      return this;
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