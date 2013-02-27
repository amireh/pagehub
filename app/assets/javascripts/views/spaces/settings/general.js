define(
'views/spaces/settings/general',
[ 'backbone', 'jquery', 'pagehub', 'hb!dialogs/destroy_space.hbs' ],
function(Backbone, $, UI, DestroySpaceDlgTmpl) {

  var SpaceGeneralSettingsView = Backbone.View.extend({
    el: $("#space_general_settings"),

    events: {
      'click #check_availability': 'check_availability',
      'click #destroy_space': 'confirm_total_destruction',
      'click #save': 'save',
      'click button': 'consume'
    },

    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx;

      this.elements = {
        title:              this.$el.find('input[type=text][name=title]'),
        title_availability: this.$el.find('#name_availability_status'),
        title_confirmation: this.$el.find('input[type=checkbox][name=title_confirmation]'),
        brief:              this.$el.find('input[type=text][name=brief]'),
        is_public:          this.$el.find('input[type=checkbox][name=is_public]')
      }
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    check_availability: function(e) {
      var btn   = $(e.target),
          name  = this.elements.title.val(),
          view  = this;

      e.preventDefault();

      if (name.length == 0) {
        view.elements.title_availability.addClass("error").html("invalid name");
        return false;
      }

      $.ajax({
        url: view.space.get("media").name_availability_url,
        type: "POST",
        data: JSON.stringify({ name: name }),

        success: function(status) {
          if (status.available) {
            view.elements.title_availability.addClass("success").removeClass("error").html("available");
          } else {
            view.elements.title_availability.addClass("error").removeClass("success").html("not available");
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
          $(this).parents('.ui-dialog:first').find('button:last').addClass('bad');
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

    save: function(e) {
      e.preventDefault();

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

      this.space.save(data, {
        patch: true,
        wait: true,
        success: function() {
          UI.status.show("Saved.", "good");
        }
      })

      return false;
    } // save
  });

  return SpaceGeneralSettingsView;
});