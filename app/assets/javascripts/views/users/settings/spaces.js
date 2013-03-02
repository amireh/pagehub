define(
'views/users/settings/spaces',
[
  'views/shared/settings/setting_view',
  'jquery',
  'pagehub',
  'hb!users/settings/dialog_leave_space_warning.hbs'
],

function(SettingView, $, UI, LeaveSpaceWarningDlgTmpl) {
  return SettingView.extend({
    el: $("#user_spaces_settings"),

    templates: {
      leave_space_warning: LeaveSpaceWarningDlgTmpl
    },

    events: {
      'click button[data-role=leave_space]': 'confirm_space_leaving'
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.elements = {
      }

      this.unserializable = true;
    },

    confirm_space_leaving: function(e) {
      var el = $(e.target),
          view = this,
          space_id = el.parents('[data-space]:first').attr('data-space');

      $(this.templates.leave_space_warning()).dialog({
        dialogClass: "alert",
        buttons: {
          Cancel: function() {
            $(this).dialog("close");
          },

          Confirm: function() {
            $(this).dialog("close");

            view.leave_space(space_id)
          }
        }
      })
    },

    leave_space: function(space_id) {
      var view  = this;
      var space = this.model.spaces.get(space_id);
      if (!space) {
        console.log("really bad, no such space");
        return this;
      }

      space.modify_membership(this.user.get('id'), null, {
        success: function() {
          UI.status.show("You are no longer a member of " + space.get('title') + ".", "good");
          view.$el.find("[data-space=" + space.get('id') + ']').remove();
        }
      })
      return this;
    },

    serialize: function() {
      return {};
    }
  });
});