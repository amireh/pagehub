define(
'views/spaces/settings/publishing',
[ 'backbone', 'jquery', 'pagehub', 'hb!spaces/settings/membership_record.hbs' ],
function(Backbone, $, UI, MembershipRecordTmpl) {

  var SpacePublishingSettingsView = Backbone.View.extend({
    el: $("#space_publishing_settings"),

    events: {
      'click button': 'consume',
      'change #layout_settings input': 'update_layout_settings',
      'change #theme_settings input': 'update_theme_settings'
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

      console.log(data);

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
    }

  });

  return SpacePublishingSettingsView;
});