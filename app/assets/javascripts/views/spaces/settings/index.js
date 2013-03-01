define(
'views/spaces/settings/index',
[
  'views/shared/settings/director',
  'jquery',
  'pagehub',
  'shortcut',
  'views/spaces/settings/router',
  'views/spaces/settings/general'
],
function(Director, $, UI, Shortcut, Router, GeneralSettings) {

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

  var SpaceSettingsView = Director.extend({
    el: $("#space_settings"),

    events: {
      'click button': 'consume'
    },

    initialize: function(data) {
      Director.prototype.initialize.apply(this, arguments);

      this.space  = data.space;
      this.ctx    = data.ctx || {};

      this.nav    = $('.settings nav');
      this.subnav = this.nav.find('.subnav');

      this.register(GeneralSettings, 'general');

      this.bootstrap();
    },

    bootstrap: function() {
      var view = this;

      this.$el.show();
      _.each(this.views, function(view) { view.$el.hide(); });

      this.router = new Router(this, 'general');

      Backbone.history.start({
        pushState: true,
        root: '/' + this.space.get('media.url') + '/edit/'
      });


    },

    show: function(section) {
      var view = _.select(this.views, function(view) { return view.path == section; })[0];

      if (!view) {
        return false;
      }

      this.trigger('section_changed', view);
      this.ctx.subview = view;

      return this;
    },

    render: function() {
      return this;
    },

    sync: function(data) {
      var view = this;

      UI.status.mark_pending();

      this.space.save(data, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Saved", "good");
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

  return SpaceSettingsView;
});