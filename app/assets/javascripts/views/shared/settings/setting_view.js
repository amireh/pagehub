define(
'views/shared/settings/setting_view',
[ 'backbone', 'jquery' ],
function(Backbone, $) {
  return Backbone.View.extend({
    initialize: function(data) {
      _.implode(this, data);
    },

    render: function() {
      if (this.unserializable) {
        if (this.ctx.save_button) {
          this.ctx.save_button.prop('disabled', true);
        }
      }

      this.$el.show("blind");

      return this;
    },

    hide: function() {
      this.$el.hide("blind");
      this.reset();

      return this;
    },

    serialize: function() {
      return false;
    },

    is_serializable: function() {
      return !this.unserializable;
    },

    reset: function() {
      this.$el.find('.control-group').removeClass('error');
      this.$el.find('.help-inline').html('');
      this.mark_destructive_action(false);

      if (this.ctx.save_button) {
        this.ctx.save_button.prop('disabled', false);
      }

      return this;
    },

    mark_destructive_action: function(active) {
      var btn = this.ctx.save_button;

      if (btn)
        btn.toggleClass('btn-danger', active);

      return this;
    },

    propagate_sync: function(no_presync_callbacks) {
      return this.director.save(no_presync_callbacks);
    },

    on_sync_error: function(errors) {
      var reported_count = 0;

      _.each(_.pairs(errors), function(entry) {
        var field   = entry[0],
            message = entry[1];

        var el = this.$el.find('#' + field);

        if (el.length == 1) {
          if (message instanceof Array) {
            message = message.join('<br />')
          }

          el.nextAll('span[class^=help]:first').html(message);
          el.parents('.control-group:first').addClass('error');

          ++reported_count;
        }

        return true;
      }, this);

      return reported_count > 0;
    }
  });
});