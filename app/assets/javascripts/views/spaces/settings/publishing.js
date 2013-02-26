define(
'views/spaces/settings/publishing',
[ 'backbone', 'jquery', 'pagehub', 'hb!spaces/settings/navigation_link.hbs' ],
function(Backbone, $, UI, NavigationLinkTmpl) {

  var SpacePublishingSettingsView = Backbone.View.extend({
    el: $("#space_publishing_settings"),

    events: {
      'click button': 'consume',
      'change #layout_settings input': 'update_layout_settings',
      'change #theme_settings input': 'update_theme_settings',
      'click #add_navigation_link': 'add_navigation_link',
      'click #save_navigation_links': 'save_navigation_links',
      'click #links button': 'remove_navigation_link'
    },

    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx;
      this._ctx   = {};

      this.elements = {
        theme_browser: this.$el.find('#theme_browser')
      }

      this.bootstrap();
    },

    bootstrap: function() {
      var view = this;
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    render: function(section) {
      if (section == "theme") {
        this.preview_theme(this.$el.find('#theme_settings input:checked').val());
      }
      else if (section == "navigation_links") {
        _.each(this.space.get('preferences.publishing.navigation_links'), function(nl) {
          this.$el.find('#links').append(NavigationLinkTmpl(nl));
          return true;
        }, this);
      }
    },

    update_layout_settings: function(e) {
      var data = $.extend(true, {
        layout: {
          name: 'fluid',
          show_homepages_in_sidebar: false,
          show_breadcrumbs: false
        }
      }, this.$el.serializeObject());

      this.space.save({
        preferences: {
          publishing: data
        }
      }, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Updated.", "good")
        }
      })
    },

    update_theme_settings: function(e) {
      var view  = this,
          el    = $(e.target),
          theme = el.val(),
          data =
      $.extend(true, {
        theme: {
          name: 'Clean'
        }
      }, this.$el.serializeObject());

      this.space.save({
        preferences: {
          publishing: data
        }
      }, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Updated.", "good")
          view.preview_theme(theme)
        }
      })
    },

    preview_theme: function(theme) {
      UI.status.mark_pending();
      this.elements.theme_browser.attr("src", this.space.get('media.url') + "/testdrive?theme=" + theme + '&embedded=true');
      UI.status.mark_ready();
      return this;
    },

    add_navigation_link: function() {
      this.$el.find('#links').append(NavigationLinkTmpl({}));
    },

    remove_navigation_link: function(e) {
      $(e.target).parents('div:first').remove();

      // this is leaking for some reason
      $("body > .tooltip:last").remove();

      return this.save_navigation_links();
    },

    save_navigation_links: function() {
      var data  = this.$el.serializeObject();

      data = _.zip(data.navigation_links.uris, data.navigation_links.titles);
      data = _.collect(data, function(entry) { return { uri: entry[0], title: entry[1] }});

      this.space.save({
        preferences: {
          publishing: {
            navigation_links: data
          }
        }
      }, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Updated.", "good");
        }
      })
    }
  });

  return SpacePublishingSettingsView;
});