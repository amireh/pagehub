// status = ui.status;
pagehub_ui = function() {
  var handlers = {
        on_entry: []
      },
      status_timer = null,
      autosave_timer = null,
      theme = "",
      anime_dur = 250,
      status_shown = false,
      status_queue = [],
      autosave_pulse = 30, /* autosave every half minute */
      defaults = {
        status: 1
      },
      actions = {},
      hooks = [
        // Bind the title editor's key presses:
        // 1. on RETURN: update the page and the entry
        // 2. on ESCAPE: hide the editor and reset the title
        function() {
          $("#title_editor").keyup(function(e) {
            if ( e.which == 13 ) {
              e.preventDefault();
              ui.save_title();
            } else if (e.which == 27) {
              e.preventDefault();
              ui.hide_title_editor();
            }
          });
        },

        // toggle autosaving
        function() {
          if (pagehub !== undefined) {
            if (pagehub.settings.editing.autosave) {
              autosave_timer = setInterval("ui.save(true)", autosave_pulse * 1000);
            }
            
          }

          // ui.status("hi", "good");
        },

        // disable all links attributed with data-disabled
        function() {
          $("a[data-disabled]").click(function(e) { e.preventDefault(); return false; });
        }
      ];

  function current_page_id() {
    if ($("#page_listing .selected").length == 0)
      return null;

    return $("#page_listing .selected").attr("id").replace("page_", "");
  }

  return {
    hooks: hooks,
    theme: theme,

    create_editor: function(textarea_id, opts) {
      opts = opts || {};
      mxvt.markdown.setup_bindings();
      var editor = CodeMirror.fromTextArea(document.getElementById(textarea_id), $.extend({
        mode: "markdown",
        lineNumbers: false,
        matchBrackets: true,
        theme: ui.theme,
        tabSize: 2,
        gutter: false,
        autoClearEmptyLines: false,
        lineWrapping: true,
        keyMap: "mxvt"
      }, opts));

      return editor;
    },

    clear_status: function(cb) {
      if (!$("#status").is(":visible"))
        return (cb || function() {})();

      $("#status").addClass("hidden").removeClass("visible");
      status_shown = false;
      
      if (cb)
        cb();

      if (status_queue.length > 0) {
        var status = status_queue.pop();
        return ui.status(status[0], status[1], status[2]);
      }
    },
    status: function(text, status, seconds_to_show) {
      if (!status)
        status = "notice";
      if (!seconds_to_show)
        seconds_to_show = defaults.status;

      // queue the status if there's one already being displayed
      if (status_shown) {
        return status_queue.push([ text, status, seconds_to_show ]);
      }

      // clear the status resetter timer
      if (status_timer)
        clearTimeout(status_timer)

      status_timer = setTimeout("ui.clear_status()", 2000);
      $("#status").removeClass("pending good bad").addClass(status + " visible").html(text);
      status_shown = true;
    },

    mark_pending: function() {
      // $(".loader").show(250);
      $(".loader").show();
    },
    mark_ready: function() {
      // $(".loader").hide(250);
      $(".loader").hide();
    },

    is_editing: function() {
      return !$("#page_actions").hasClass("disabled");
    },

    on_action: function(action, handler) {
      if (!actions[action])
        actions[action] = [];

      actions[action].push( handler );
    },

    action: function(action) {
      if (!ui.is_editing())
        return false;

      if (!actions[action])
        return true;

      foreach( actions[action], function(h) { h() } );

      return false;
    },

    save: function(dont_show_status) {
      // ui.editor.save();

      var page_id = current_page_id();
      if (!page_id)
        return;

      var content = ui.editor.getValue();
      var messages = null;

      if (!dont_show_status) {
        messages = {
          success: "Saved!",
          error: "Unable to update page :("
        }
      }

      pagehub.update(page_id, { content: content }, messages);
    },

    save_title: function() {
      var page_id = current_page_id();
      if (!page_id)
        return;
      var title = $("#title_editor").attr("value");
      
      ui.hide_title_editor(true);


      ui.status("Saving page title...", "pending");
      pagehub.update(page_id, { title: title }, {
        success: "Page title updated!",
        error: "Unable to update the page's title :("
      });
    },

    show_title_editor: function() {
      var li = $("#page_listing li.selected");
      var txtbox = $("#title_editor");

      li.hide();
      txtbox.show().attr("value", li.find("a").html());
      li.after(txtbox);
      txtbox.focus();

      return true;
    },

    hide_title_editor: function(update_title) {
      var li = $("#page_listing li.selected");
      var txtbox = $("#title_editor");

      if (update_title)
        li.find("a").html(txtbox.attr("value"));

      txtbox.hide();
      li.show();
    },

    destroy_page: function() {
      var page_id = current_page_id();
      if (!page_id)
        return;

      var entry = $("#page_listing .selected");
      var page_title = entry.html();
      pagehub.destroy(page_id, function() {
        ui.status("Page " + page_title + " is now dead :(", "good");
        entry.remove();
        ui.editor.setValue("");
        ui.actions.addClass("disabled");
        $("#page_listing li:last").click();
      }, function() {
        ui.status("Page could not be destroyed! Please try again.", "bad");
      });
    },

    destroy_group: function(a) {
      window.location.href = $(a).attr("href");
      return false;
    },

    destroy: function() {
      var page_id = current_page_id();
      if (!page_id)
        return;

      $("a.confirm#destroy_page").click();      
    },

    preview: function() {
      var id = current_page_id();
      if (!id)
        return true;

      window.open("/pages/" + id + "/pretty", "_pretty")
    }
  }
}

// globally accessible instance
ui = new pagehub_ui();

$(function() {
  foreach(ui.hooks, function(hook) { hook(); });
})