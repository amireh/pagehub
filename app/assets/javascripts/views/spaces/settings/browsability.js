define(
'views/spaces/settings/browsability',
[ 'views/shared/settings/setting_view', 'jquery', 'pagehub' ],
function(SettingView, $, UI, DestroySpaceDlgTmpl) {

  var SpaceGeneralSettingsView = SettingView.extend({
    el: $("#space_browsability_settings"),

    events: {
      'change input[name^=folders]': 'update_folder_browsability',
      'change input[name^=pages]':   'update_page_browsability'
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.space.folders.on('change:browsable', this.adjust_folder_contents_browsability, this);
      this.space.folders.on('change:pages.browsable', this.adjust_page_browsability, this);

      this.unserializable = true;

      this.bootstrap();
    },

    bootstrap: function() {
      this.space.folders.every(function(f) {
        f.trigger('change:browsable', f);
        return true;
      });
    },

    // disables or enables all child resources of a folder when its
    // browsability has changed
    adjust_folder_contents_browsability: function(f) {
      var on = f.get('browsable'),
          el = $('input[name^=folders][value=' + f.get('id') + ']');

      el.parents('li:first')
      .find('> ol').attr("disabled", !on)
      .find('label').toggleClass('disabled', !on)
      .find('input').attr("disabled", !on)

      return true;
    },

    serialize: function() {
      return false;
    },

    update_resource_browsability: function(r, value) {
      r.save({ browsable: value }, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Saved", "good");
        }
      });
    },

    update_folder_browsability: function(e) {
      var el      = $(e.target),
          id      = el.val(),
          on      = el.is(":checked"),
          folder  = this.space.folders.get(id);

      return this.update_resource_browsability(folder, on);
    },

    update_page_browsability: function(e) {
      var el      = $(e.target),
          id      = el.val(),
          on      = el.is(":checked"),
          folder  = this.space.folders.get(el.parents('li:first').attr('data-folder')),
          page    = folder.pages.get(id);

      return this.update_resource_browsability(page, on);
    }
  });

  return SpaceGeneralSettingsView;
});