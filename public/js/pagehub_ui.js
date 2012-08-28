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
      current_status = null,
      status_queue = [],
      animation_dur = 2500,
      autosave_pulse = 30, /* autosave every half minute */
      defaults = {
        status: 1
      },
      actions = {},
      removed = {},
      hooks = [
        // Bind the title editor's key presses:
        // 1. on RETURN: update the page and the entry
        // 2. on ESCAPE: hide the editor and reset the title
        function() {
          $("#resource_editor input[type=text]").keyup(function(e) {
            if ( e.which == 13 ) {
              e.preventDefault();
              ui.resource_editor.save();
            } else if (e.which == 27) {
              e.preventDefault();
              ui.resource_editor.hide();
            }
          }).click(function(e) {
            e.preventDefault();
          });

          $("#update_title").click(function() { 
            return ui.resource_editor.save();
          });
          $("#cancel_title_editing").click(function() {
            return ui.resource_editor.hide();
          })
        },

        // toggle autosaving
        function() {
          if (pagehub !== undefined) {
            if (pagehub.settings.editing.autosave) {
              autosave_timer = setInterval("ui.pages.save(true)", autosave_pulse * 1000);
            }
          }
        },

        // disable all links attributed with data-disabled
        function() {
          $("a[data-disabled]").click(function(e) { e.preventDefault(); return false; });
        }
      ];

  function current_page_id() {
    if (!ui.is_page_selected())
      return null;

    return ui.current_page().attr("id").replace(/\w+_/, "");
  }

  function current_folder_id() {
    if (!ui.is_folder_selected()) {
      return null;
    }

    return ui.current_folder().parent().attr("id").replace("folder_", "");
  }

  return {
    hooks: hooks,
    theme: theme,

    current_page: function() {
      return $("#page_listing li.selected:not(.folder) a");
    },

    current_folder: function() {
      return $("#page_listing .folder > .selected");
    },

    is_page_selected: function() {
      return ui.current_page().length != 0;
    },
    is_folder_selected: function() {
      return ui.current_folder().length != 0;
    },

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

    status: {
      clear: function(cb) {
        if (!$("#status").is(":visible"))
          return (cb || function() {})();

        $("#status").addClass("hidden").removeClass("visible");
        status_shown = false;
        
        if (cb)
          cb();

        if (status_queue.length > 0) {
          var status = status_queue.pop();
          return ui.status.show(status[0], status[1], status[2]);
        }
      },

      show: function(text, status, seconds_to_show) {
        if (!status)
          status = "notice";
        if (!seconds_to_show)
          seconds_to_show = defaults.status;

        // queue the status if there's one already being displayed
        if (status_shown && current_status != "pending") {
          return status_queue.push([ text, status, seconds_to_show ]);
        }

        // clear the status resetter timer
        if (status_timer)
          clearTimeout(status_timer)

        status_timer = setTimeout("ui.status.clear()", status == "bad" ? animation_dur * 2 : animation_dur);
        $("#status").removeClass("pending good bad").addClass(status + " visible").html(text);
        status_shown = true;
        current_status = status;
      },

      mark_pending: function() {
        // $(".loader").show(250);
        $(".loader").show();
      },
      mark_ready: function() {
        // $(".loader").hide(250);
        $(".loader").hide();
      }
    },

    is_editing: function() {
      return ui.is_page_selected() && !$("#page_actions").hasClass("disabled");
    },

    on_action: function(action, handler, props) {
      
      var defaults = {
        is_editor_action: true
      }

      var props = $.extend(defaults, props || {});

      if (!actions[action])
        actions[action] = { props: props, handlers: [] };

      actions[action].handlers.push( handler );
      // log("Registered action: " + action);
    },

    action: function(action_id) {
      var action = actions[action_id];

      if (!action)
        return true;

      if (!ui.is_editing() && action.props.is_editor_action)
        return false;

      foreach( action.handlers, function(h) { h() } );

      return false;
    },

    resource_editor: {
      show: function() {
        if (!ui.is_folder_selected() && !ui.is_page_selected()) {
          console.log("ERROR: nothing is selected, can't show resource editor");
          return;
        }

        var li      = ui.is_folder_selected()
                      ? ui.current_folder() : ui.current_page(),
            form    = $("#resource_editor"),
            txtbox  = form.find("input[type=text][name=title]");

        li.hide();
        form.show();
        li.after(form);
        txtbox.attr("value", li.html().trim()).focus();

        if (ui.is_folder_selected()) {
          var parent = li.parent().attr("data-parent");
          parent = parent == "%parent" ? 0 : parent;

          form.find("select :selected").attr("selected", null);
          form.find("select option[value=folder_" + parent + "]")
                .attr("selected", "selected");

          // we have to hide any children folders from the parent
          // selection because that's not allowed
          li.parent().find("li.folder").add(li.parent()).each(function() {
            form.find("select option[value=" + $(this).attr("id") + "]").hide();
          });                
        }
        // $(window).bind('click', ui.save_title);

        return true;
      },

      hide: function(update_title) {
        if (!ui.is_folder_selected() && !ui.is_page_selected()) {
          console.log("ERROR: nothing is selected, can't show resource editor");
          return;
        }

        var li      = ui.is_folder_selected()
                      ? ui.current_folder() : ui.current_page(),
            form    = $("#resource_editor"),
            txtbox  = form.find("input[type=text][name=title]");

        if (update_title)
          li.html(txtbox.attr("value"));

        form.hide();
        li.show();

        if (ui.is_folder_selected()) {
          li.siblings("button[data-dyn-action=remove]:hidden").show();
          ui.dehighlight("folder");
          form.find("option:hidden").show();
          $("#parent_folder_selection").hide();
        }

        // $(window).unbind('click', ui.save_title);
      },

      save: function() {
        var resource_id = null;

        if (!ui.is_folder_selected() && !ui.is_page_selected()) {
          console.log("ERROR: nothing is selected, can't show resource editor");
          return;
        }

        var title = $("#resource_editor input[type=text][name=title]").attr("value");
        
        // is it a folder?
        if (ui.is_folder_selected()) {
          resource_id   = current_folder_id(),
          parent_folder = $("#parent_folder_selection select :selected").attr("value").replace("folder_", "");

          ui.status.show("Updating folder...", "pending");
          pagehub.folders.update(resource_id, title, parent_folder,
            function(f) {
              var f = JSON.parse(f);
              ui.folders.on_update(f);
            },
            function(rc) {
              ui.status.show("Unable to update folder: " + rc.responseText, "bad");
            });

        } else {
          resource_id = current_page_id();

          // nope, a page
          ui.status.show("Saving page title...", "pending");
          pagehub.pages.update(resource_id, { title: title }, {
            success: "Page title updated!",
            error: "Unable to update page."
          });
        }

        ui.resource_editor.hide(true);
      }

    },

    dialogs: {
      destroy_group: function(a) {
        window.location.href = $(a).attr("href");
        return false;
      },

      destroy_page: function() {
        if (!ui.is_page_selected())
          return false;

        $("a.confirm#destroy_page").click();      
      },
    },

    highlight: function(el) {
      el = el || $(this);
      ui.dehighlight(el.hasClass("folder_title") ? "folder" : "page");
      el.addClass("selected");
      if (!ui.is_folder_selected()) {
        el.append( $("#indicator").show() );
      }
    },

    dehighlight: function(type) {
      if (type == "folder")
        ui.current_folder().removeClass("selected");
      else
        ui.current_page().parent().removeClass("selected");
      // $("#page_listing .selected").removeClass("selected");
    },

    folders: {
      on_update: function(f) {
        ui.status.show("Folder updated!", "good");

        // if its parent has changed, we need to reorder
        // it and re-sort the folder listing
        var folder = $("#folder_" + f.id);
        folder.attr("data-parent", f.parent || "%parent");
        folder.find("> span:first").html(f.title);
        ui.folders.arrange($("#page_listing"));

        // update the Move-To action for this folder
        $("a[data-action=move][data-folder=" + f.id + "]").html(f.title);

        // update the resource editor parent folder selection menu
        $("#resource_editor option[value=folder_" + f.id + "]").html(f.title);
      }, 

      on_injection: function(el) {
        // toggle the "This folder is empty" label if it has any pages
        if (el.find("> ol > li[data-dyn-index][data-dyn-index!=-1]").length > 0) {
          el.find("> ol > li:first").hide();
        } else {
          el.find("> ol > li:first").show();          
        }

        // if it's the general folder, we don't want to display its title
        if (el.attr("id") == "folder_0") {
          el.addClass("general-folder");
          el.find("> button[data-dyn-action=remove]").remove();
          el.find("> a[data-action=move]").remove();
          el.find("> select").remove();
        } else {

          // add the folder to the "Move to folder" listing
          var movement_entry = el.find("a[data-action=move]");
          if (movement_entry.length == 1) {
            $("#movement_listing").append('<li></li>').find("li:last").append(movement_entry);
          }

          // and to the parent folder selection in the resource editor
          $("#parent_folder_selection select")
            .append('<option value="' + el.attr("id") 
              + '">' + el.find("> span").html()
              + '</option>');
        }
      },

      arrange: function(ul) {
        ui.status.mark_pending();

        ul.prepend(ul.find('[data-parent=\\\%parent]:visible'));

        ul.find('> li.folder[data-parent]:not([data-parent=\\\%parent]):visible').each(function() {
          var parent_id = parseInt($(this).attr("data-parent"));
          var parent = $("#folder_" + parent_id);
          if (parent.length == 1) {
            // parent.append('<ul></ul>');
            parent.find("> ol").append($(this));
          } else {
            console.log("[ERROR]: Unknown parent!")
          }
        });

        // sort the folders alphabetically
        // code adapted from: http://www.onemoretake.com/2009/02/25/sorting-elements-with-jquery/
        var __sort_folders = function(ul) {
          ul.find("> li.folder:visible")
            .sort(function(a, b) {
              var compA = $(a).find("> span:first-child").html().trim().toUpperCase();
              var compB = $(b).find("> span:first-child").html().trim().toUpperCase();
              return (compA < compB) ? -1 : (compA > compB) ? 1 : 0;
            }).each(function(idx, itm) { ul.append(itm); });
        }
        __sort_folders(ul);
        ul.find("ol > li.folder:visible").each(function() {
          __sort_folders($(this).parent());
        })

        // keep the general folder at the bottom of the list
        var general_folder 
          = $("#page_listing").find(".folder.general-folder");
            $("#page_listing").append(general_folder);

        ui.status.mark_ready();
     
      },

      edit_title: function() {
        if ($("#resource_editor").is(":visible"))
          ui.resource_editor.hide();

        ui.highlight($(this));
        $(this).siblings("button[data-dyn-action=remove]:visible").hide();
        $("#parent_folder_selection").show();

        return ui.resource_editor.show();
      },

      /**
       * Requests the folder to be deleted from the server
       * and defers the dynamism removal. If the request succeeds,
       * the dynamism  action is invoked again, and the folder's pages
       * are moved to the general folder.
       */
      on_removal: function(el, btn) {
        var folder_id = el.attr("id").replace("folder_", "");

        if (!removed[el.attr("id")]) {
          pagehub.folders.destroy(folder_id,
            // success handler
            function() {
              // now remove it
              removed[el.attr("id")] = true;

              // orphanize its pages into the general folder
              $("#page_listing li.folder.general-folder")
                .append(el.find("> ol li[data-dyn-entity]:visible"));

              btn.click();

              // remove the Move-To link
              $("a[data-action=move][data-folder=" + folder_id + "]").parent().remove();
              // and the resource editor parent folder selection option
              $("#resource_editor option[value=folder_" + folder_id + "]").remove();

              ui.status.show("Folder deleted.", "good");
            },

            // error handler
            function() {
              ui.status.show("Unable to delete folder.", "bad");
            });

          // don't let dynamism remove the listing just yet
          throw "Halting.";
        }
      }, // pagehub_ui.folders.on_removal

      highlight: function() {
        var span = $(this);
        if ($(this).hasClass("highlighted")) {
          $("span.folder_title.highlighted").removeClass("highlighted");
        } else {
          $(this).addClass("highlighted");
          $(this).parents(".folder").find("> span.folder_title").addClass("highlighted");
        }
      }
    },

    pages: {
      load: function() {
        if ($(this).parent().hasClass("selected")) {
          ui.resource_editor.show();
          return false;
        }

        $("#page_actions").removeClass("disabled");

        ui.resource_editor.hide();

        ui.highlight($(this).parent());

        // ui.status.show("Loading page...", "pending");
        ui.status.mark_pending();

        ui.editor.save();

        var title = $(this).attr("id").replace("page_", "");
        $.ajax({
          type: "GET",
          url: "/pages/" + title + ".json",
          success: function(page) {
            var page    = JSON.parse(page),
                content = page.content,
                groups  = page.groups;

            ui.editor.clearHistory();
            ui.editor.setValue(content);
            $("#preview").attr("href", "/pages/" + title + "/pretty");
            $("#share_everybody").attr("href", "/pages/" + title + "/share");

            // Disable the group share links for all the groups this page
            // is already shared with
            $("a[data-action=share][data-group]").each(function() {
              var group           = $(this).attr("data-group"),
                  already_shared  = false;

              for (var i = 0; i < groups.length; ++i) {
                if (groups[i] == group) {
                  $(this).attr("data-disabled", true);
                  already_shared = true;
                  break;
                }
              }

              if (!already_shared) {
                $(this).attr("href", "/pages/" + title + "/share/" + group);
                $(this).attr("data-disabled", null);
              } else {
                $(this).attr("href", null);
                $(this).attr("data-disabled", true);
              }
            });

            // disable the "move to" of the folder the page is in, if any
            $("a[data-action=move]").attr("data-disabled", null);
            $("a[data-action=move][data-folder=" + page.folder + "]")
            .attr({ "data-disabled": true });

            // $("a[data-action=move]").unbind('click');
            $("a[data-action=move]").each(function() {
              $(this).attr("href", 
                "/folders/" 
                + $(this).attr("data-folder")
                + "/add/" + page.id);
            });

            ui.editor.focus();
          },
          complete: function() {
            ui.status.mark_ready();          
          }
        });

        return false;
      }, // pagehub_ui.pages.load

      save: function(dont_show_status) {
        // ui.editor.save();
        if (!ui.is_page_selected())
          return;

        var page_id   = current_page_id(),
            content   = ui.editor.getValue(),
            messages  = null;

        if (!dont_show_status) {
          messages = {
            success: "Saved!",
            error: "Unable to update page :("
          }
        }

        pagehub.pages.update(page_id, { content: content }, messages);
      }, // pagehub_ui.pages.save

      destroy: function() {
        if (!ui.is_page_selected())
          return;

        var entry       = ui.current_page(),
            page_id     = current_page_id(),
            page_title  = entry.html(); // for status

        pagehub.pages.destroy(page_id,
          // success
          function() {
            ui.status.show("Page " + page_title + " has been deleted.", "good");
            entry.parent().remove();
            ui.editor.setValue("");
            ui.actions.addClass("disabled");
            ui.resource_editor.hide();
          },
          function() {
            ui.status.show("Page could not be destroyed! Please try again.", "bad");
          }); // pagehub.pages.destroy
      },

      move: function() {
        if ($(this).attr("data-disabled"))
          return false;

        var uri         = $(this).attr("href"),
            page_li     = ui.current_page().parent(),
            last_folder = page_li.parents("li.folder:first"),
            folder_id   = $(this).attr("data-folder");

        $.ajax({
          url: uri,
          type: "PUT",
          success: function(page) {
            var page    = JSON.parse(page),
                folder  = $("#folder_" + page.folder);

            var current_listing = page_li.parent();

            // 1. move the page <li> to the folder's
            folder.find("> ol > li:not(.folder):last").after(page_li);
            // 2. remove the folder's empty status if it's empty
            folder.find("> ol > li:first").hide();

            if (current_listing.find("> li:not(.folder):visible").length == 0)
              current_listing.find("> li:first:hidden").show();

            // re-enable the move-to link for the old folder
            $("a[data-action=move][data-folder=" + last_folder.attr("id").replace("folder_", "") + "]")
            .attr("data-disabled", null);
            $("a[data-action=move][data-folder=" + page.folder + "]")
            .attr({ "data-disabled": true });
          },
          error: function(e) {
            last_error = e;
            ui.status.show(e.responseText, "bad");
          }
        });

        return false;
      }, // pagehub_ui.pages.move

      /** Launches the Pretty mode of the current page in the preview tab. */
      preview: function() {
        if (!ui.is_page_selected())
          return true; // let the event propagate

        window.open("/pages/" + current_page_id() + "/pretty", "_pretty")
      }
    }
  }
}

// globally accessible instance
ui = new pagehub_ui();

$(function() {
  foreach(ui.hooks, function(hook) { hook(); });
})