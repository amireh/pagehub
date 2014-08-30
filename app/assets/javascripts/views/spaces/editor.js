define([
  'jquery',
  'backbone',
  'cm/lib/codemirror',
  'cm/addon/fold/foldcode',
  'cm/addon/fold/foldgutter',
  'cm/addon/fold/brace-fold',
  'cm/addon/fold/markdown-fold',
  'cm/addon/dialog/dialog',
  'cm/addon/search/searchcursor',
  'cm/addon/search/search',
  'cm/addon/selection/active-line',
  'cm/addon/display/rulers',
  'cm/keymap/emacs',
  'cm/keymap/sublime',
  'cm/keymap/vim',
  'cm/mode/markdown/markdown',
  'cm/mode/gfm/gfm',
  'cm/mode/lua/lua',
  'cm/mode/htmlembedded/htmlembedded',
  'cm/mode/htmlmixed/htmlmixed',
  'cm/mode/xml/xml',
  'cm/mode/shell/shell',
  'cm/mode/ruby/ruby',
  'cm/mode/javascript/javascript',
  'cm/mode/clike/clike',
  'cm/mode/coffeescript/coffeescript',
  'cm/mode/css/css',
  'cm/mode/diff/diff',
  'cm/mode/erlang/erlang',
  'cm/mode/go/go',
  'cm/mode/http/http',
  'cm/mode/nginx/nginx',
  'cm/mode/perl/perl',
  'cm/mode/php/php',
  'cm/mode/puppet/puppet',
  'cm/mode/python/python',
  'cm/mode/sass/sass',
  'cm/mode/sql/sql',
  'cm/mode/yaml/yaml',
], function($, Backbone, CodeMirror) {

  var CodeMirror_aliases = {
    'shell': [ 'bash', 'sh' ]
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

    var RULER = 80;

    // mxvt.markdown.setup_bindings();
    var editor = CodeMirror.fromTextArea(document.getElementById(textarea_id), $.extend({
      mode: "gfm",
      lineNumbers: false,
      matchBrackets: true,
      theme: "neat",
      tabSize: 2,
      indentUnit: 2,
      gutter: false,
      lineNumbers: false,
      foldGutter: true,
      gutters: [ "CodeMirror-foldgutter" ],
      autoClearEmptyLines: false,
      lineWrapping: true,
      styleActiveLine: true,
      rulers: [ RULER ],
      keyMap: "sublime",
      onKeyEvent: function(editor,e) {
        if (editor_disabled) {
          e.preventDefault();
          e.stopPropagation();
          return true;
        } else {
          return false;
        }
      },
    }, opts));

    return editor;
  }

  var EditorView = Backbone.View.extend({
    el: $("#page_editor"),

    ctx: { },

    initialize: function(data) {
      _.implode(this, data);

      this.config = $.extend({
        el: "#page_editor",
        offset: 115
      }, (this.config || {}));

      this.$el = $(this.config.el);

      if (this.workspace) {
        this.workspace.on('page_loaded', this.populate_editor, this);
        this.workspace.on('workspace_layout_changed', this.refresh, this);
        this.workspace.on('refresh_editor', this.refresh, this);
        this.workspace.on('reset', this.reset, this);

        this.state.on('bootstrapped', this.refresh, this);
      }

      var view = this;

      if (!this.config.no_resize) {
        $(window).on('resize', function() {
          return view.resize_editor();
        });
      }

      this.bootstrap();
    },

    bootstrap: function() {
      this.editor = create_editor(this.$el.attr("id"), this.config);
      this.resize_editor();

      return this;
    },

    reset: function() {
      this.editor.setValue('Load or create a new page to begin.');
      this.editor.clearHistory();
      this.refresh();

      return this;
    },

    refresh: function() {
      this.editor.refresh();

      return this;
    },

    // Resize it to fill up the remainder of the screen's height
    resize_editor: function(offset) {
      if (this.config.no_resize) {
        return this;
      }

      this.editor.setSize(null, $(window).height() - (offset || this.config.offset));

      return this;
    },

    disable_editor: function() {
      editor_disabled = true;
      $(this.editor.getWrapperElement()).addClass("disabled");

      return this;
    },
    enable_editor: function() {
      $(this.editor.getWrapperElement()).removeClass("disabled");
      editor_disabled = false;

      return this;
    },

    // TODO: move this out of here
    populate_editor: function(page) {
      var cursor = this.editor.getCursor(),
          scroll = this.editor.getScrollInfo();

      this.reset();
      if (page) {
        this.editor.setValue(_.unescape( page.get('content') ));
      }

      this.editor.markClean();
      this.editor.setCursor(cursor);
      this.editor.scrollTo(scroll.left, scroll.top);
      this.editor.focus();

      this.editor.clearHistory();

      return this;
    },

    focus: function() {
      this.editor.focus();

      return this;
    },

    content_changed: function() {
      return !this.editor.isClean();
    },

    serialize: function() {
      this.editor.save();

      if (this.workspace && this.workspace.current_page) {
        this.workspace.current_page.set('content', this.editor.getValue());
      }

      return this.editor.getValue();
    }
  });

  return EditorView;
});