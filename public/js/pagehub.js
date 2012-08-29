foreach = function(arr, handler) {
  arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
}

log = function(m, ctx) { ctx = ctx || "D"; console.log("[" + ctx + "] " + m); }

pagehub = function() {
  var config = { resource: "" };
  return {
    config: config,
    
    pages: {
      create: function(handlers) {
        var uri = config.resource + "/pages";

        ui.status.mark_pending();

        console.log("Creating a page from " + uri);

        $.ajax({
          url: uri,
          type: "POST",
          success: handlers.success,
          error: handlers.error,
          complete: function() { ui.status.mark_ready(); }
        });
      },

      update: function(page_id, attributes, messages) {
        var uri = config.resource + "/pages/" + page_id;

        ui.status.mark_pending();
        $.ajax({
          type: "PUT",
          url: uri,
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
        var uri = config.resource + "/pages/" + page_id;

        ui.status.mark_pending();
        $.ajax({
          type: "DELETE",
          url: uri,
          success: on_success,
          error: on_error,
          complete: function() { ui.status.mark_ready(); }
        });
      },
    },


    folders: {
      create: function(data, handlers) {
        var uri = config.resource + "/folders";
        ui.status.mark_pending();

        $.ajax({
          url: uri,
          type: "POST",
          data: data,
          success: handlers.success,
          error: handlers.error,
          complete: function() { ui.status.mark_ready(); }        
        });
      },

      update: function(folder_id, title, parent, on_success, on_error) {
        var uri = config.resource + "/folders/" + folder_id;

        ui.status.mark_pending();
        $.ajax({
          type: "PUT",
          url: uri,
          data: { title: title, folder_id: parent },
          success: on_success,
          error: on_error,
          complete: function() { ui.status.mark_ready(); }
        })
      },

      destroy: function(in_id, on_success, on_error) {
        var in_id = in_id,
            uri   = config.resource + "/folders/" + in_id;

        if (!in_id)
          throw "undefined id given to pagehub.folders.destroy: " + in_id;

        in_id = parseInt(in_id);
        
        if (isNaN(in_id) || in_id == 0) {
          throw "bad id given to pagehub.folders.destroy: " + in_id;
        }

        ui.status.mark_pending();
        $.ajax({
          type: "DELETE",
          url: uri,
          success: on_success,
          error: on_error,
          complete: function() { ui.status.mark_ready(); }
        });
      }
    }
  }    
};

// globally accessible instance
pagehub = new pagehub();

pagehub.settings = pagehub_settings;
pagehub_settings = null;