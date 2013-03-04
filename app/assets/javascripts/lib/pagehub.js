// status = ui.status;
define('pagehub', [ 'underscore', 'jquery', 'bootstrap', 'hb!dialogs/connectivity_issue.hbs' ], function(_, $, undefined, ConnectivityIssueDlg) {
  var __init = false,
      timers = {
        flash: null,
        status: null
      },
      loader = null,
      loader_overlay = null;
      anime_dur = 250,
      status_shown = false,
      current_status = null,
      status_queue = [],
      animation_dur = 2500,
      pulses = {
        flash: 2.5
      },
      defaults = {
        status: 1
      };

  function show_list() {
    if ($(this).parent("[disabled],:disabled,.disabled").length > 0)
      return false;

    hide_list($("a.listlike.selected"));

    var list = $(this).nextAll("ol.listlike:first");

    list.css({ left: 0, right: 0 });

    if (list.width() + list.parent().offset().left >= $(window).width()) {
      list.css({ right: 0, left: -1 * list.width() });
    } else {
      list.css({ left: $(this).position().left, right: 0 });
    }

    list.show();

    $(this).addClass("selected");
    $(this).unbind('click', show_list);
    $(this).add($(window)).bind('click', hide_list_callback);

    return false;
  }

  function hide_list_callback(e) {
    e.preventDefault();

    hide_list($(".listlike.selected:visible"));

    return false;
  }

  var dont_hide_list = false;

  function hide_list(el) {
    if (dont_hide_list) {
      dont_hide_list = false;
      return true;
    }

    $(el).removeClass("selected");
    $(el).nextAll("ol.listlike:first").hide();
    $(el).add($(window)).unbind('click', hide_list_callback);
    $(el).bind('click', show_list);
  }

  var ui = {};

  $(document).ajaxStart(function(xhr)     { ui.status.mark_pending(); });
  $(document).ajaxComplete(function(xhr)  { ui.status.mark_ready();   });
  $(document).ajaxError(function(xhr, e) {
    if (e.__pagehub_no_status)
      return true;

    console.log(e);
    if (e.status != 200) {
      try {
        var err = JSON.parse(e.responseText);
        ui.status.show(err.messages.join('<br />'), "bad", null, true);
      } catch(err) {
        // TODO: show some alert and report the error
        e.exception = err.message;
        $(ConnectivityIssueDlg(e)).dialog({
          dialogClass: "alert-dialog",
          buttons: {
            Dismiss: function() {
              $(this).dialog('close');
            }
          }
        })
      }
    }
  });

  $.extend($.ui.dialog.prototype.options, {
    modal: true,
    resizable: false,
    create: function(e, ui) {
      // $(this).dialog("widget").siblings('.ui-dialog').remove();
      $(this).dialog("widget").find('button').addClass('btn');
    },
    close: function() {
      $(this).remove();
    },
    open: function() {
      var dlg = $(this);

      dlg.find('.ui-dialog-buttonpane button:last').focus();
      dlg.find('form').submit(function(e) { e.preventDefault(); return false; });
      dlg.keypress(function(e) {
        if( e.keyCode == 13 ) {
          dlg.parent().find('.ui-dialog-buttonpane button:last').click();
          return false;
        }
      });
    }
  });

  // $(function() {
  var init = function() {
    if (__init) {
      return true;
    }

    if (!Modernizr.draganddrop) {
      ui.modal.as_alert($("#html5_compatibility_notice"))
    }

    $(document.body).tooltip({
      selector: '[rel=tooltip]',
      container: 'body',
      animation: false,
      placement: function(_, el) {
        return $(el).attr('data-placement') || 'bottom'
      }
    });

    $(document.body).popover({
      selector: '[rel=popover]',
      animation: false,
      trigger: 'hover',
      container: 'body',
      placement: function(_, el) {
        return $(el).attr('data-placement') || 'bottom'
      }
    });

    loader = $(".loader");
    loader_overlay = $(".loader-overlay");

    // Togglable sections
    // $("section:not([data-untogglable])").
    //   find("> h1:first-child, > h2:first-child, > h3:first-child").
    //   addClass("togglable");

    // $("section > .togglable").click(function() {
    //   $(this).siblings(":not([data-untogglable])").toggle();
    //   $(this).toggleClass("toggled")
    // })

    // disable all links attributed with data-disabled
    $("a[data-disabled], a.disabled").click(function(e) { e.preventDefault(); return false; });

    // "listlike" links
    $("a.listlike:not(.selected)").bind('click', show_list);
    $("ol.listlike:not(.sticky) li:not(.sticky)").click(function() {
      var anchor = $(this).parent().prev("a.listlike");
      if (anchor.hasClass("selected")) {
        hide_list(anchor);
      }

      return true; // let the event propagate
    });
    $("ol.listlike.sticky li, ol.listlike:not(.sticky) li.sticky").on('click', function(e) { dont_hide_list = true; return true; });

    __init = true;
  // });
  }();

  ui = {
    pbar_tick:  0,
    pbar_value: 0,

    status: {
      clear: function(cb) {
        if (!$("#status").is(":visible"))
          return (cb || function() {})();

        $("#status").addClass("hidden").removeClass("visible");
        status_shown = false;

        if (cb)
          cb();

        if (status_queue.length > 0) {
          var __status = status_queue.pop();
          return this.status.show(__status[0], __status[1], __status[2]);
        }
      },

      show: function(text, status, seconds_to_show, no_escape) {
        if (!status)
          status = "notice";
        if (!seconds_to_show)
          seconds_to_show = defaults.status;

        // queue the status if there's one already being displayed
        // if (status_shown && current_status != "pending") {
        //   return status_queue.push([ text, status, seconds_to_show ]);
        // }

        // clear the status resetter timer
        if (timers.status)
          clearTimeout(timers.status)

        timers.status = setTimeout(function() { ui.status.clear() }, status == "bad" ? animation_dur * 2 : animation_dur);
        $("#status").removeClass("pending good bad").addClass(status + " visible");

        if (no_escape)
          $("#status").html(text);
        else
          $("#status").text(text);

        status_shown = true;
        current_status = status;
      },

      mark_pending: function() {
        loader.show();
        // loader_overlay.show("fade");
      },

      mark_ready: function() {
        loader.hide();
        // loader_overlay.hide("fade");
      }
    },

    report_error: function(err_msg) {
      ui.status.show("A script error has occured, please try to reproduce the bug and report it.", "bad");
      console.log(err_msg);
    }
  }; // ui

  return ui;
})
