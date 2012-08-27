foreach = function(arr, handler) {
  arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
}

log = function(m, ctx) { ctx = ctx || "D"; console.log("[" + ctx + "] " + m); }

pagehub = function() { };

// Replaces [ and ] with \\\[ and \\\] respectively.
// This is required for jQuery selectors locating attribute values that
// contain any bracket
function jquery_escape_query(str) {
  return str.replace(/\[/g, '\\\[').replace(/\]/g, '\\\]');
}

pagehub.prototype = {

  pages: {
    update: function(page_id, attributes, messages) {
      ui.status.mark_pending();
      $.ajax({
        type: "PUT",
        url: "/pages/" + page_id,
        data: { attributes: attributes },
        success: function() {
          if (messages && messages.success)
            ui.status.show(messages.success, "good");
        },
        error: function(rc) {
          if (messages && messages.error)
            ui.status.show(messages.error + " " + rc.responseText, "bad");
        },
        complete: function() { ui.status.mark_ready(); }
      })
    },
    
    destroy: function(page_id, on_success, on_error) {
      ui.status.mark_pending();
      $.ajax({
        type: "DELETE",
        url: "/pages/" + page_id,
        success: on_success,
        error: on_error,
        complete: function() { ui.status.mark_ready(); }
      });
    },
  },


  folders: {
    update: function(folder_id, title, parent, on_success, on_error) {
      ui.status.mark_pending();
      $.ajax({
        type: "PUT",
        url: "/folders/" + folder_id,
        data: { title: title, folder_id: parent },
        success: on_success,
        error: on_error,
        complete: function() { ui.status.mark_ready(); }
      })
    },

    destroy: function(in_id, on_success, on_error) {
      var in_id = in_id;

      if (!in_id)
        throw "undefined id given to pagehub.folders.destroy: " + in_id;

      in_id = parseInt(in_id);
      
      if (isNaN(in_id) || in_id == 0) {
        throw "bad id given to pagehub.folders.destroy: " + in_id;
      }

      ui.status.mark_pending();
      $.ajax({
        type: "DELETE",
        url: "/folders/" + in_id,
        success: on_success,
        error: on_error,
        complete: function() { ui.status.mark_ready(); }
      });
    }
  }
}

// globally accessible instance
pagehub = new pagehub();

pagehub.settings = pagehub_settings;
pagehub_settings = null;