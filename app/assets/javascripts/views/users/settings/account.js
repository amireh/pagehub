define(
'views/users/settings/account',
[
  'views/shared/settings/setting_view',
  'jquery',
  'hb!users/settings/dialog_nickname_change_warning.hbs'
 ],
function(SettingView, $, NnWarningDlgTmpl) {
  return SettingView.extend({
    el: $("#user_account_settings"),

    templates: {
      nickname_change_warning: NnWarningDlgTmpl
    },

    events: {
      'click #change_nickname':     'show_nickname_change_warning',
      'click #change_password':     'propagate_sync',
      'click #check_availability':  'check_availability',
      'keyup input[name=nickname]': 'queue_availability_check',
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.check_timer = null;
      this.check_pulse = 250;
      this.elements = {
        nickname:               this.$el.find('input[name=nickname]'),
        availability_checker:   this.$el.find('#check_availability'),
        nickname_availability:  this.$el.find('#check_availability i'),
        current_password:       this.$el.find('input[name=current_password]'),
        passwords:              this.$el.find('input[name^=password]'),
        password:               this.$el.find('input[name=password]'),
        password_confirm:       this.$el.find('input[name=password_confirmation]')
      }

      this.director.before_sync(this, this.show_nickname_change_warning);

      this.user.on('change:nickname', this.update_public_href_example, this);
      this.elements.current_password.on('keyup', this, this.unlock_password_form);
      this.reset();
    },

    serialize: function() {
      var data = this.$el.serializeObject();

      if (data.current_password.length == 0) {
        delete data['password'];
        delete data['password_confirmation']
        delete data['current_password'];
      }

      return data;
    },

    reset: function() {
      SettingView.prototype.reset.apply(this);

      this.elements.current_password.val('').trigger('keyup');
      this.elements.passwords.val('');

      return this;
    },

    update_public_href_example: function() {
      this.$el.find('#user_public_href_example_nickname').html(this.user.get('nickname'));
      return this;
    },

    unlock_password_form: function(e) {
      var view  = e.data,
          input = $(e.target);

      view.elements.passwords.attr("disabled", input.val().length < 7);

      return true;
    },

    show_nickname_change_warning: function() {
      var view = this;

      if (this.user.get('nickname') == this.elements.nickname.val()) {
        return true;
      }

      $(view.templates.nickname_change_warning()).dialog({
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
          name  = this.elements.nickname.val(),
          view  = this;

      // e.preventDefault();

      if (name.length == 0) {
        btn.addClass('btn-danger').removeClass('btn-success').find('i').addClass('icon-remove');
        return false;
      }
      else if (name.trim() == this.model.get('nickname')) {
        this.mark_destructive_action(false);
        return false;
      }

      $.ajax({
        url: view.model.get("media").name_availability_url,
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

  });
});