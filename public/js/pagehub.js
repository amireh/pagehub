foreach = function(arr, handler) {
  arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
}

log = function(m, ctx) { ctx = ctx || "D"; console.log("[" + ctx + "] " + m); }

pagehub = function() {
  var config = { resource: "" };
  var namespace = "";
  $(document).ajaxStart(function() {
    ui.status.mark_pending();
  });
  $(document).ajaxComplete(function(xhr) {
    ui.status.mark_ready();
  });

  return {
    config: config,
    namespace: namespace,

    pages: {
      create: function(handlers) {
        var uri = pagehub.namespace + "/pages";

        $.ajax({
          url: uri,
          type: "POST",
          success: handlers.success,
          error: handlers.error
        });
      },

      update: function(page_id, attributes, handlers) {
        var uri = pagehub.namespace + "/pages/" + page_id;

        $.ajax({
          type: "PUT",
          url: uri,
          data: { attributes: attributes },
          success: handlers.success,
          error: handlers.error
        })
      },
      
      destroy: function(page_id, on_success, on_error) {
        var uri = pagehub.namespace + "/pages/" + page_id;

        $.ajax({
          type: "DELETE",
          url: uri,
          success: on_success,
          error: on_error
        });
      },
    },


    folders: {
      create: function(data, handlers) {
        var uri = pagehub.namespace + "/folders";

        $.ajax({
          url: uri,
          type: "POST",
          data: data,
          success: handlers.success,
          error: handlers.error    
        });
      },

      update: function(folder_id, title, parent, on_success, on_error) {
        var uri = pagehub.namespace + "/folders/" + folder_id;

        $.ajax({
          type: "PUT",
          url: uri,
          data: { title: title, folder_id: parent },
          success: on_success,
          error: on_error
        })
      },

      destroy: function(in_id, on_success, on_error) {
        var in_id = in_id,
            uri   = pagehub.namespace + "/folders/" + in_id;

        if (!in_id)
          throw "undefined id given to pagehub.folders.destroy: " + in_id;

        in_id = parseInt(in_id);
        
        if (isNaN(in_id) || in_id == 0) {
          throw "bad id given to pagehub.folders.destroy: " + in_id;
        }

        $.ajax({
          type: "DELETE",
          url: uri,
          success: on_success,
          error: on_error
        });
      }
    }
  }    
};

// globally accessible instance
pagehub = new pagehub();

pagehub.settings = pagehub_settings;
pagehub_settings = null;