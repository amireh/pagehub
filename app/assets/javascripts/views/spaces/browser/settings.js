define('views/spaces/browser/settings',
[ 'backbone', 'hbs!templates/browser/settings' ], function(Backbone, Tmpl) {
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

      this.user.on('change:preferences.workspace.browser.type', this.update_dialog, this);
      this.$el.hide();

      this.toggler = $('#show_browser_settings');

      var view = this;
      // this.$el.dialog();

      this.update_dialog();

      // this.$el.dialog("close");
      this.$el.dialog({
        dialogClass: "popdown",
        modal: false,
        autoOpen: false,
        title: 'Browser Settings',
        show: {
          effect: "blind"
        },

        hide: {
          effect: "blind"
        },

        open: function() {
          view.state.UI.dialog.on_open($(this));
          view.$el.dialog("widget").find('button:last').addClass('btn btn-success');

          view.toggler.addClass('active');
        },
        close: function() {
          view.toggler.removeClass('active');
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

    },

    update_dialog: function() {
      var view = this,
          data = this.template(this.user.get('preferences.workspace.browser') || {});

      // var was_open = this.$el.dialog("isOpen");
      this.$el.html(data);
      // this.$el.dialog("destroy");


      // if (was_open) {
      //   this.$el.dialog("open");
      // }
    },

    render: function() {
      var view = this;

      this.$el.dialog("open");

      return this;
    },

    serialize: function() {
      return { preferences: { workspace: { browser: this.$el.find('form').serializeObject() } } };
    },

    switch_browser_type: function(e) {
      // var type = $(e.target).val();
      // console.log('switching to ' + type + ' browser');

      this.state.trigger('sync_runtime_preferences_now', this.serialize());
      // this.$el.hide();
    }
  })
});