define('views/spaces/editor',
[ 'jquery', 'backbone' ],
function($, Backbone) {

  var CodeMirror_aliases = {
    "shell": [ "bash" ]
  };
  var editor_disabled = false;
  var create_editor = function(textarea_id, opts) {
    opts = opts || {};
    for(var mode in CodeMirror_aliases) {
      if (!CodeMirror.modes[mode])
        continue;
      
      var aliases = CodeMirror_aliases[mode];
      for (var alias_idx = 0; alias_idx < aliases.length; ++alias_idx) {
        var alias = aliases[alias_idx];
        if (!CodeMirror.modes[alias]) {
          CodeMirror.defineMode(alias, CodeMirror.modes[mode]);
        }
      }
    }
    
    // mxvt.markdown.setup_bindings();
    var editor = CodeMirror.fromTextArea(document.getElementById(textarea_id), $.extend({
      mode: "gfm",
      lineNumbers: false,
      matchBrackets: true,
      theme: "neat",
      tabSize: 2,
      gutter: false,
      autoClearEmptyLines: false,
      lineWrapping: true,
      onKeyEvent: function(editor,e) {
        if (editor_disabled) {
          e.preventDefault();
          e.stopPropagation();
          return true;
        } else {
          return false;
        }
      }
      // keyMap: "mxvt",
    }, opts));

    editor.on("change", function() {
      pagehub.content_changed = true;
    });
    
    return editor;
  }
  
  var EditorView = Backbone.View.extend({
    el: $("#page_editor"),
    
    ctx: { },
    
    initialize: function(data) {
      this.space  = data.space;
      this.ctx    = data.ctx;
      this.space.on('page_loaded', this.populate_editor, this);
      this.bootstrap();
    },
    
    bootstrap: function() {
      this.editor = create_editor("page_editor");
      this.resize_editor();
    },
    
    // Resize it to fill up the remainder of the screen's height
    resize_editor: function() {
      var editor_h = $(window).height() - 135;
      $(".CodeMirror").css("height", editor_h + "px");
    },
    
    populate_editor: function(page) {
      this.editor.clearHistory();
      this.editor.setValue(page.get('content'));
    },
    
    serialize: function() {
      this.editor.save();
      this.ctx.current_page.set('content', this.editor.getValue());
    }
  });
  
  return EditorView;
});