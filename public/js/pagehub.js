foreach = function(arr, handler) {
  arr = arr || []; for (var i = 0; i < arr.length; ++i) handler(arr[i]);
}

log = function(m, ctx) { ctx = ctx || "D"; console.log("[" + ctx + "] " + m); }

Array.prototype.has_value = function(v) {
  for (var i = 0; i < this.length; ++i)
    if (this[i] == v) return true;

  return false;
}

Array.prototype.pop_value = function(v) {
  var index = -1;
  while ((index = this.indexOf(v)) != -1 ) {
    this.splice(index, 1);
  }

  return this;
}

pagehub = function() {
  var config = { resource: "" },
      namespace = "",
      settings_changed = false,
      content_changed = false,
      setting_sync_uri = "/profile/preferences/runtime";

  $(document).ajaxStart(function() {
    ui.status.mark_pending();
  });
  $(document).ajaxComplete(function(xhr) {
    ui.status.mark_ready();
  });

  return {
    config: config,
    namespace: namespace,
    settings_changed: settings_changed,
    content_changed: content_changed,

    sync: function() {
      // any changes pending?
      if (!pagehub.settings_changed) {
        return;
      }

      $.ajax({
        url: setting_sync_uri,
        type: "PUT",
        data: { settings: pagehub.settings.runtime },
        error: function(e) {
          ui.report_error("Unable to synchronize user settings: " + e.responseText);
        },
        complete: function() { 
          pagehub.settings_changed = false;
        }
      })
    },

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

      update: function(folder_id, attributes, on_success, on_error) {
        var uri = pagehub.namespace + "/folders/" + folder_id;

        $.ajax({
          type: "PUT",
          url: uri,
          data: attributes,
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
      } // folders.destroy
    }, // pagehub.folders

    groups: {
      kick: function(id, gid, handlers) {
        var uri = "/groups/" + gid + "/kick/" + id;
        $.ajax({
          type: "PUT",
          url: uri,
          success: handlers.success,
          error: handlers.error
        })
      }
    }
  } // pagehub.return
}; // pagehub

// globally accessible instance
pagehub = new pagehub();

pagehub.settings = pagehub_settings;
if (!pagehub.settings.runtime) {
  pagehub.settings.runtime = { cf: [] }
}
pagehub_settings = null;