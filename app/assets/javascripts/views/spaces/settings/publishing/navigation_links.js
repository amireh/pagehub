define(
'views/spaces/settings/publishing/navigation_links',
[
  'backbone',
  'views/shared/settings/setting_view',
  'hb!spaces/settings/navigation_link.hbs'
],
function(Backbone, SettingView, NavigationLinkTmpl) {
  return SettingView.extend({
    el: $("form#navigation_links_settings"),

    events: {
      'click #add_navigation_link':     'add_navigation_link',
      'click #navigation_links button': 'remove_navigation_link'
    },

    initialize: function(ctx) {
      SettingView.prototype.initialize.apply(this, arguments);
      this.links = this.$el.find('#navigation_links');
    },

    render: function() {
      SettingView.prototype.render.apply(this, arguments);

      this.links.empty();

      _.each(this.space.get('preferences.publishing.navigation_links'), function(nl) {
        return this.links.append(NavigationLinkTmpl(nl)) || true;
      }, this);

      return this;
    },

    serialize: function() {
      var data  = this.$el.serializeObject();

      if (data.navigation_links) {
        data = _.zip(data.navigation_links.uris, data.navigation_links.titles);
        data = _.collect(data, function(entry) { return { uri: entry[0], title: entry[1] }});
      } else {
        data = [];
      }

      return {
        navigation_links: data
      };
    },

    add_navigation_link: function() {
      this.links.append(NavigationLinkTmpl({}));
      return true;
    },

    remove_navigation_link: function(e) {
      $(e.target).parents('div:first').remove();

      // this is leaking for some reason
      $("body > .tooltip:last").remove();

      return this.propagate_sync();
    }
  });
});