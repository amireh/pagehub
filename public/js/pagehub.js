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

  update: function(page_id, attributes, messages) {
    ui.mark_pending();
    $.ajax({
      type: "PUT",
      url: "/pages/" + page_id,
      data: { attributes: attributes },
      success: function() {
        if (messages && messages.success)
          ui.status(messages.success, "good");
      },
      error: function(rc) {
        if (messages && messages.error)
          ui.status(messages.error + " " + rc.responseText, "bad");
      },
      complete: function() { ui.mark_ready(); }
    })
  },

  destroy: function(page_id, on_success, on_error) {
    ui.mark_pending();
    $.ajax({
      type: "DELETE",
      url: "/pages/" + page_id,
      success: on_success,
      error: on_error,
      complete: function() { ui.mark_ready(); }
    });
  }
}

// globally accessible instance
pagehub = new pagehub();

pagehub.settings = pagehub_settings;
pagehub_settings = null;