naughty = function() { };

naughty.prototype = {

  update: function(page_id, attributes, messages) {
    $.ajax({
      type: "PUT",
      url: "/pages/" + page_id,
      data: { attributes: attributes },
      success: function() {
        ui.status(messages.success, "good");
      },
      error: function(rc) {
        ui.status(messages.error + " " + rc.responseText, "bad");
      }
    })
  },

  delete: function(page_id, on_success, on_error) {
    $.ajax({
      type: "DELETE",
      url: "/pages/" + page_id,
      success: on_success,
      error: on_error
    });
  }
}

// globally accessible instance
naughty = new naughty();