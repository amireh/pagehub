define('views/flash',
[
  'timed_operation'
], function(TimedOp) {
  return Backbone.View.extend({
    el: $("#flash"),

    events: {
      'click #hide_flash': 'hide'
    },

    template: null,

    initialize: function(app) {
      this.hide_button = this.$el.find('#hide_flash');
      this.anime_duration = app.get('preferences.animes.toggling_duration');
      if (this.$el.is(":visible")) {
        var pulse = null;

        this.hide();
        this.$el.removeClass('hidden');
        this.__show_proxy = $.proxy(this.show, this);
        this.hidden_top_offset =
          -1 *
          (this.$el.height() +
           Math.ceil( 0.5 * (parseInt(this.$el.css('padding-bottom')))));

        if (this.$el.hasClass('error')) {
          pulse = app.get('preferences.pulses.flash.error');
        } else {
          pulse = app.get('preferences.pulses.flash.notice');
          this.is_notice = true;
        }

        this.pulse = pulse;

        this.hide_timer = new TimedOp(this, this.hide, {
          pulse: pulse
        });

        this.render();
      }
    },

    render: function(additional_data) {
      this.$el.css({
        top: 0,
        cursor: "default"
      });
      // this.$el.addClass('visible');
      this.$el.off('click', this.__show_proxy);
      this.hide_timer && this.hide_timer.queue();

      return this;
    },

    hide: function() {
      var view = this;

      this.$el.css({
        top: this.hidden_top_offset,
        cursor: "pointer"
      });

      this.hide_timer && this.hide_timer.cancel();

      if (this.is_notice) {
        setTimeout(function() { view.$el.hide(); }, 400);

        return this;
      }

      this.$el.on('click', this.__show_proxy);

      return this;
    },

    show: function() {
      return this.render();
    }

  });
});