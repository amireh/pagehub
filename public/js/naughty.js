foreach = function(arr, handler) {
  arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
}

log = function(m, ctx) { ctx = ctx || "D"; console.log("[" + ctx + "] " + m); }

naughty = function() { };

naughty.prototype = {

  update: function(page_id, attributes, messages) {
    ui.mark_pending();
    $.ajax({
      type: "PUT",
      url: "/pages/" + page_id,
      data: { attributes: attributes },
      success: function() {
        ui.status(messages.success, "good");
      },
      error: function(rc) {
        ui.status(messages.error + " " + rc.responseText, "bad");
      },
      complete: function() { ui.mark_ready(); }
    })
  },

  delete: function(page_id, on_success, on_error) {
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
naughty = new naughty();