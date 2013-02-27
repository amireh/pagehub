define(
'views/spaces/settings/publishing',
[
  'backbone',
  'jquery',
  'pagehub',
  'shortcut',
  'views/spaces/settings/publishing/router',
  'views/spaces/settings/publishing/theme',
  'views/spaces/settings/publishing/layout',
  'views/spaces/settings/publishing/navigation_links',
  'views/spaces/settings/publishing/custom_css'
],
function(Backbone, $, UI, Shortcut, Router, ThemeSettings, LayoutSettings, NavigationLinksSettings, CustomCSSSettings) {

  // All navigation that is relative should be passed through the navigate
  // method, to be processed by the router.  If the link has a data-bypass
  // attribute, bypass the delegation completely.
  $(document).on("click", ".subnav a:not([data-bypass])", function(evt) {
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

  var SpacePublishingSettingsView = Backbone.View.extend({
    el: $("#space_publishing_settings"),

    events: {
      'click button': 'consume'
    },

    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx || {};
      this.ctx.main_view = this;
      this._ctx   = {};

      this.nav    = $('.settings nav');
      this.subnav = this.nav.find('.subnav');

      this.on('section_changed', this.show_section, this);
      this.on('section_changed', this.highlight_section_in_subnav, this);

      this.views = [
        new LayoutSettings(this.ctx),
        new ThemeSettings(this.ctx),
        new NavigationLinksSettings(this.ctx),
        new CustomCSSSettings(this.ctx)
      ];

      this.bootstrap();
    },

    bootstrap: function() {
      var view = this;

      this.$el.show();
      _.each(this.views, function(view) { view.$el.hide(); });

      this.router = new Router(this.ctx);

      Backbone.history.start({
        pushState: true,
        root: '/' + this.space.get('media.url') + '/edit/publishing/'
      });

      Shortcut.add("ctrl+alt+s", function() { view.update(); });
      Shortcut.add("ctrl+alt+v", function() { window.open(view.space.get('media.href'), '_preview'); });
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

    show_section: function(view, initial) {
      _.each(this.views, function(view) { view.$el.hide("blind"); });
      view.$el.show("blind");
      view.render();

      return true;
    },

    highlight_section_in_subnav: function(view) {
      this.subnav.
      find('.selected').removeClass('selected').end().
      find('a[href=' + view.path + ']').parent().addClass('selected');

      return true;
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    render: function() {
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