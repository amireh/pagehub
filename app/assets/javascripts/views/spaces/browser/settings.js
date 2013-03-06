define('views/spaces/browser/settings',
[ 'backbone', 'hb!browser/settings.hbs' ], function(Backbone, Tmpl) {
  return Backbone.View.extend({
    el:       $("#browser_settings"),
    events: {
      'change input': 'switch_browser_type',
      // 'click button': 'switch_browser_type'
    },

    template: Tmpl,

    initialize: function(data) {
      this.browser  = data.browser;
      this.state    = data.browser.state;
      this.user     = data.browser.state.current_user;

      this.$el.hide();
    },

    render: function() {
      var view = this;

      var el = this.template(this.user.get('preferences.workspace.browser') || {});

      this.$el.html(el).show();
      this.form = this.$el.find('form');

      this.$el.dialog({
        dialogClass: "popdown",
        title: this.form.prop('title'),
        show: {
          effect: "blind"
        },

        hide: {
          effect: "blind"
        },

        open: function() {
          view.state.UI.dialog.on_open($(this));
          $(this).dialog("widget").find('button:last').addClass('btn btn-success');
        },
        close: function() {
          // view.switch_browser_type();
        },

        buttons: {
          Cancel: function() {
            $(this).dialog("close");
          },

          Save: function() {
            view.switch_browser_type();
            $(this).dialog("close");
          }
        }
      });

      return this;
    },

    serialize: function() {
      return { preferences: { workspace: { browser: this.form.serializeObject() } } };
    },

    switch_browser_type: function(e) {
      // var type = $(e.target).val();
      // console.log('switching to ' + type + ' browser');

      this.state.trigger('sync_runtime_preferences', this.serialize());
      // this.$el.hide();
    }
  })
});