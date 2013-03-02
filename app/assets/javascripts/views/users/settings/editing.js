define(
'views/users/settings/editing',
[
  'views/shared/settings/setting_view',
  'views/spaces/editor',
  'jquery'
],
function(SettingView, Editor, $) {
  return SettingView.extend({
    el: $("#user_editing_settings"),

    templates: {
    },

    events: {
      'change input[type=radio], input[type=checkbox]': 'propagate_sync',
      // 'change #editor_font_face_list input': 'preview',
      // 'keyup  #editor_font_dim_settings': 'preview'
    },

    initialize: function(data) {
      SettingView.prototype.initialize.apply(this, arguments);

      this.elements = {
        autosave: this.$el.find('input[name=autosave]'),
        font_face_list: this.$el.find('#editor_font_face_list'),
        font_size: this.$el.find('[name=font_size]'),
        line_height: this.$el.find('[name=line_height]'),
        letter_spacing: this.$el.find('[name=letter_spacing]')
      }

      this.director.on('postfetch', function(_, model) {
        this.elements.autosave.prop('checked', model.get('preferences.editing.autosave'));

        this.elements.font_face_list
        .find('[checked], :checked').prop('checked', false).end()
        .find('[value="' + model.get('preferences.editing.font_face') + '"]').prop('checked', true);

        this.elements.font_size.val(model.get('preferences.editing.font_size'));
        this.elements.line_height.val(model.get('preferences.editing.line_height'));
        this.elements.letter_spacing.val(model.get('preferences.editing.letter_spacing'));

        this.preview();

      }, this);

      this.editor = new Editor({ config: { el: $("#preview_editor"), no_resize: true } });

      // $("input[type=radio][name*=editing]").change(function() {
      //   var ff = $(this).parent().css("font-family");
      //   console.log(ff)
      //   $(".CodeMirror").css("font-family", ff);
      // });
      // $("input[type=text][name*=editing\\\]\\\[font_size]").keyup(function(e) {
      //   if (e.keyCode == 38) { $(this).attr("value", parseInt($(this).attr("value")) + 1);}
      //   else if (e.keyCode == 40) { $(this).attr("value", parseInt($(this).attr("value")) - 1);}
      //   $(".CodeMirror").css("font-size", parseInt($(this).attr("value") || 1) + "px");
      // });
      // $("input[type=text][name*=editing\\\]\\\[line_height]").keyup(function(e) {
      //   if (e.keyCode == 38) { $(this).attr("value", parseInt($(this).attr("value")) + 1);}
      //   else if (e.keyCode == 40) { $(this).attr("value", parseInt($(this).attr("value")) - 1);}
      //   $(".CodeMirror").css("line-height", parseInt($(this).attr("value") || 1) + "px");
      // });
      // $("input[type=text][name*=editing\\\]\\\[letter_spacing]").keyup(function(e) {
      //   if (e.keyCode == 38) { $(this).attr("value", parseInt($(this).attr("value")) + 1);}
      //   else if (e.keyCode == 40) { $(this).attr("value", parseInt($(this).attr("value")) - 1);}
      //   $(".CodeMirror").css("letter-spacing", parseInt($(this).attr("value") || 0) + "px");
      // });

      this.preview();
    },

    preview: function() {
      $(this.editor.editor.getWrapperElement()).css({
        'font-family':    this.model.get('preferences.editing.font_face'),
        'font-size':      this.model.get('preferences.editing.font_size') + 'px',
        'line-height':    this.model.get('preferences.editing.line_height') + 'px',
        'letter-spacing': this.model.get('preferences.editing.letter_spacing') + 'px'
      });

      this.editor.editor.refresh();

      return this;
    },

    serialize: function() {
      var data = this.$el.serializeObject();

      data.autosave = data.autosave == 'true' ? true : false;
      _.each([ 'font_size', 'line_height', 'letter_spacing' ], function(k) {
        data[k] = parseInt(data[k]);
      });

      return { preferences: { editing: data } };
    }
  });
});