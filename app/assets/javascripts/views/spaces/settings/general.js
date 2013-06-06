define(
'views/spaces/settings/general',
[ 'views/shared/settings/setting_view', 'jquery', 'pagehub',
'hbs!templates/dialogs/destroy_space',
'hbs!templates/spaces/settings/dialog_change_title_warning',
'hbs!templates/messages/relocation_error',
],
function(SettingView, $, UI, DestroySpaceDlgTmpl, ChangeTitleDlgTmpl, RelocationErrorTmpl) {

  var SpaceGeneralSettingsView = SettingView.extend({
    el: $("#space_general_settings"),

    events: {
      'click #check_availability': 'check_availability',
      'keyup input[type=text][name=title]': 'queue_availability_check',
      'click #destroy_space': 'confirm_total_destruction',
      'change input[type=checkbox]': 'propagate_sync'
    },

    templates: {
      title_change_warning: ChangeTitleDlgTmpl,
      relocation_error: RelocationErrorTmpl
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

      this.director.before_sync(this, this.show_title_change_warning);
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

    hide: function() {
      SettingView.prototype.hide.apply(this);

      this.elements.title.val(this.space.get('title'));

      return this;
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
        this.mark_destructive_action(false);
        return false;
      }

      $.ajax({
        url: view.space.get("media").name_availability_url,
        type: "POST",
        data: JSON.stringify({ name: name }),

        success: function(status) {
          if (status.available) {
            btn.removeClass('btn-danger').addClass('btn-success').find('i').removeClass('icon-remove');
            view.mark_destructive_action(true);
          } else {
            btn.removeClass('btn-success').addClass('btn-danger').find('i').addClass('icon-remove');
            view.mark_destructive_action(false);
          }
        }
      });

      return false;
    }, // check_availability

    show_title_change_warning: function() {
      var view = this;

      if (this.space.get('title') == this.elements.title.val()) {
        return true;
      }

      $(view.templates.title_change_warning()).dialog({
        dialogClass: "alert-dialog",
        buttons: {
          "Cancel": function() {
            $(this).dialog("close");
          },

          "Confirm": function() {
            $(this).dialog("close");
            view.propagate_sync(true);
          }
        }
      });

      this.director.abort_sync = true;
      return false;
    },

    confirm_total_destruction: function(e) {
      var view    = this;

      e.preventDefault();

      $(DestroySpaceDlgTmpl(this.space.toJSON())).dialog({
        title: "Space removal",
        dialogClass: "alert-dialog",
        open: function() {
          $(this).parents('.ui-dialog:first').find('button:last').addClass('btn-danger');
        },
        buttons: {
          Cancel: function() {
            $(this).dialog("close");
          },
          Destroy: function(e) {
            var dlg = $(this);
            view.space.destroy({
              wait: true,
              success: function() {
                window.location = '/';
                // show some message if we were unable to relocate using JS (some browsers don't allow that)
                dlg.dialog("close");
                $('<div>' + view.templates.relocation_error() + '</div>').dialog({
                  modal: true,
                  dialogClass: "alert-dialog no-close",
                  resizable: false,
                  closeOnEscape: false,
                  title: "Relocation Error"
                });
              }
            });
            e.preventDefault();
          }
        }
      });

      return false;
    },

    serialize: function() {
      var data = this.$el.serializeObject();

      // if ((data.title || "").length > 0 && data.title != this.space.get('title')) {
      //   if (!this.elements.title_confirmation.is(":checked")) {
      //     $("<p>You must confirm changing the space title!</p>").dialog({
      //       title: "Confirmation required",
      //       dialogClass: "alert-dialog",
      //       buttons: {
      //         Ok: function() {
      //           $(this).dialog("close");
      //         }
      //       }
      //     });

      //     return false;
      //   }
      // }

      data.is_public = data.is_public == 'true' ? true : false;

      return data;
    }

  });

  return SpaceGeneralSettingsView;
});