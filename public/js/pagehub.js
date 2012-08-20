pagehub = function() { };

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
pagehub = new pagehub();

pagehub.settings = pagehub_settings;
pagehub_settings = null;