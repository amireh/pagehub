define('views/users/settings/router',
[
  'backbone'
], function(Backbone) {

  // All navigation that is relative should be passed through the navigate
  // method, to be processed by the router.  If the link has a data-bypass
  // attribute, bypass the delegation completely.
  $(document).on("click", ".settings nav a:not([data-bypass]), a[data-routeme]", function(evt) {
    // Get the absolute anchor href.
    var href = { prop: $(this).prop("href"), attr: $(this).attr("href") };
    // Get the absolute root.
    // var root = location.protocol + "//" + location.host + app.root;

    // Ensure the root is part of the anchor href, meaning it's relative.
    // if (href.prop.slice(0, root.length) === root) {
      // Stop the default event to ensure the link will not cause a page
      // refresh.
      evt.preventDefault();

      // `Backbone.history.navigate` is sufficient for all Routers and will
      // trigger the correct events. The Router's internal `navigate` method
      // calls this anyways.  The fragment is sliced from the root.
      Backbone.history.navigate(href.attr, true);
    // }
  });

  var UserSettingsRouter = Backbone.Router.extend({

    routes: {
      "":         "initial_section",
      ":section": "section"
    },

    initialize: function(view, initial_section) {
      this.view            = view;
      this.initial_section = initial_section;
    },

    initial_section: function() {
      return this.navigate(this.initial_section, { trigger: true, replace: true });
    },

    section: function(section) {
      return this.view.trigger('section_changed', section);
    }

  });

  return UserSettingsRouter;
})