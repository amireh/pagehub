define(
'views/spaces/settings/general',
[ 'views/spaces/settings/setting_view', 'jquery', 'pagehub', 'hb!dialogs/destroy_space.hbs' ],
function(SettingView, $, UI, DestroySpaceDlgTmpl) {

  var SpaceGeneralSettingsView = SettingView.extend({
    el: $("#space_general_settings"),

    events: {
      'click [data-role=save]': 'propagate_sync',
      'click #check_availability': 'check_availability',
      'keyup input[type=text][name=title]': 'queue_availability_check',
      'click #destroy_space': 'confirm_total_destruction'
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.check_timer = null;
      this.check_pulse = 250;
      this.elements = {
        title:                this.$el.find('input[type=text][name=title]'),
        availability_checker: this.$el.find('#check_availability'),
        title_availability:   this.$el.find('#check_availability i'),
        title_confirmation:   this.$el.find('input[type=checkbox][name=title_confirmation]'),
        brief:                this.$el.find('input[type=text][name=brief]'),
        is_public:            this.$el.find('input[type=checkbox][name=is_public]')
      }
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
            // view.elements.title_availability.removeClass('icon-ok').addClass('icon-remove');
            btn.removeClass('btn-danger').addClass('btn-success').find('i').removeClass('icon-remove');
          } else {
            btn.removeClass('btn-success').addClass('btn-danger').find('i').addClass('icon-remove');
            // view.elements.title_availability.removeClass('icon-remove').addClass('icon-ok');
          }
        }
      });


      return false;
    }, // check_availability

    confirm_total_destruction: function(e) {
      var view    = this,
          dialog  =

      e.preventDefault();

      $(DestroySpaceDlgTmpl(this.space.toJSON())).dialog({
        title: "Space removal",
        open: function() {
          $(this).parents('.ui-dialog:first').find('button:last').addClass('btn-danger');
        },
        buttons: {
          Cancel: function() {
            $(this).dialog("close");
          },
          Destroy: function(e) {
            view.space.destroy({
              wait: true,
              success: function() { dialog.dialog("close"); }
            });

            e.preventDefault();
          }
        }
      });

      return false;
    },

    serialize: function() {
      var data = this.$el.serializeObject();

      if ((data.title || "").length > 0 && data.title != this.space.get('title')) {
        if (!this.elements.title_confirmation.is(":checked")) {
          $("<p>You must confirm changing the space title!</p>").dialog({
            title: "Confirmation required",
            buttons: {
              Ok: function() {
                $(this).dialog("close");
              }
            }
          });

          return false;
        }
      }

      data.is_public = data.is_public == 'true' ? true : false;

      return data;
    }

  });

  return SpaceGeneralSettingsView;
});