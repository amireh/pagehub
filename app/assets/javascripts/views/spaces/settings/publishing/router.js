define('views/spaces/settings/publishing/router',
[
  'backbone'
], function(Backbone) {

  var PublishingSettingsRouter = Backbone.Router.extend({

    initialize: function(ctx) {
      this.view  = ctx.main_view;
    },

    routes: {
      "": "layout",
      "layout":            "layout",
      "theme":             "theme",
      "custom_css":        "custom_css",
      "navigation_links":  "navigation_links"
    },

    layout:           function() { return this.view.show('layout');            },
    theme:            function() { return this.view.show('theme');             },
    custom_css:       function() { return this.view.show('custom_css');        },
    navigation_links: function() { return this.view.show('navigation_links');  }

  });

  return PublishingSettingsRouter;
})