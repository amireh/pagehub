define(
'views/spaces/new',
[ 'backbone', 'jquery', 'pagehub' ],

function(Backbone, $, UI) {

  var NewSpaceView = Backbone.View.extend({
    el: $("#new_space"),

    events: {
      'click #check_availability': 'check_availability',
      'keyup input[type=text][name=title]': 'queue_availability_check'
    },

    initialize: function(app) {
      this.space = app.space;

      this.check_timer = null;
      this.check_pulse = 250;
      this.elements = {
        title:                this.$el.find('input[type=text][name=title]'),
        availability_checker: this.$el.find('#check_availability'),
        title_availability:   this.$el.find('#check_availability i'),
        brief:                this.$el.find('input[type=text][name=brief]'),
        is_public:            this.$el.find('input[type=checkbox][name=is_public]')
      }

      app.trigger('bootstrapped', app);
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    queue_availability_check: function() {
      if (this.check_timer) {
        clearTimeout(this.check_timer);
        this.check_timer = null;
      }

      var view = this;
      this.check_timer = setTimeout(function() { return view.check_availability(); }, this.check_pulse)

      return false;
    },

    check_availability: function() {
      var btn   = this.elements.availability_checker,
          name  = this.elements.title.val(),
          view  = this;

      // e.preventDefault();

      if (name.length == 0) {
        btn.addClass('btn-danger').removeClass('btn-success').find('i').addClass('icon-remove');
        return false;
      }
      else if (name.trim() == this.space.get('title')) {
        return false;
      }

      $.ajax({
        url: view.space.get("media").name_availability_url,
        type: "POST",
        data: JSON.stringify({ name: name }),

        success: function(status) {
          if (status.available) {
            btn.removeClass('btn-danger').addClass('btn-success').find('i').removeClass('icon-remove');
          } else {
            btn.removeClass('btn-success').addClass('btn-danger').find('i').addClass('icon-remove');
          }
        }
      });

      return false;
    }, // check_availability

  });

  return NewSpaceView;
});