var mxvt = { markdown: {}, marker: null }

mxvt.markdown.heading = function(cm, level) {
  var cursor = cm.getCursor(true);
  var line = cm.getLine(cursor.line);
  var hashes = '';
  for (i = 0; i < level; ++i) { hashes += '#'; }
  var repl = hashes + ' ';
  if (line.search(repl) == 0)
    repl = '';
  cm.setLine(cursor.line, repl + line.replace(/(#+)\s+/, ''));
};

mxvt.markdown.strongify = function(cm) {
  var was_something_selected = false;
  var cursor = cm.getCursor();
  // cursor hack for proper "look-behind" tokenizing
  cursor.ch += cursor.ch == 0 ? 1 : -1;

  was_something_selected = true;

  var tok = cm.getTokenAt(cursor);
  console.log(tok);

  var em_range = {
    begin: { line: cursor.line, ch: tok.start - 2},
    end: { line: cursor.line, ch: tok.end + 2}
  };

  var prefix = cm.getRange(em_range.begin, em_range.end);
  console.log(prefix);
  if (prefix.match(/\*{2}.*\*{2}/)) {
    cm.replaceRange(tok.string, em_range.begin, em_range.end)
  } else {
    cm.replaceRange("**" + tok.string + "**",
      { line: cursor.line, ch: tok.start},
      { line: cursor.line, ch: tok.end}
    )
    cm.setCursor({ line: cursor.line, ch: tok.end + (tok.string.length == 0 ? 2 : 0) });
  }
}

mxvt.markdown.emphasize = function(cm) {
  var was_something_selected = false;
  var cursor = cm.getCursor();
  // cursor hack for proper "look-behind" tokenizing
  cursor.ch += cursor.ch == 0 ? 1 : -1;

  was_something_selected = true;

  var tok = cm.getTokenAt(cursor);
  console.log(tok);

  var em_range = {
    begin: { line: cursor.line, ch: tok.start - 2},
    end: { line: cursor.line, ch: tok.end + 2}
  };

  var prefix = cm.getRange(em_range.begin, em_range.end);
  console.log(prefix);
  if (prefix.match(/\*{1}.*\*{1}/)) {
    cm.replaceRange(tok.string, em_range.begin, em_range.end)
  } else {
    cm.replaceRange("*" + tok.string + "*",
      { line: cursor.line, ch: tok.start},
      { line: cursor.line, ch: tok.end}
    )
    cm.setCursor({ line: cursor.line, ch: tok.end + (tok.string.length == 0 ? 2 : 0) });
  }
}

function swap_text(altable) {
  var alt_txt = altable.attr("data-alt");
  var txt = altable.html();
  altable.html(alt_txt);
  altable.attr("data-alt", txt);
}

function status(msg, type) {
  ui.status(msg, type);
  // $("#status").show().removeClass("success error").addClass(type).html(msg);
}

// status = ui.status;
mxvt_ui = function() {
  var handlers = {
    on_entry: []
  };
  var status_timer = null;
  var anime_dur = 250;
  var status_shown = false;
  var status_queue = [];
  var defaults = {
    status: 1
  };

  return {
    clear_status: function(cb) {
      if (!$("#status").is(":visible"))
        return (cb || function() {})();

      // $("#status").hide("slide", {}, anime_dur, function() {
      // $("#status").hide();
      $("#status").addClass("hidden").removeClass("visible");
        status_shown = false;
        
        if (cb)
          cb();

        if (status_queue.length > 0) {
          var status = status_queue.pop();
          return ui.status(status[0], status[1], status[2]);
        }
      // });
      // $("#status").html("");
    },
    status: function(text, status, seconds_to_show) {
      if (!status)
        status = "notice";
      if (!seconds_to_show)
        seconds_to_show = defaults.status;

      if (status_shown) {
        return status_queue.push([ text, status, seconds_to_show ]);
      }

      if (status_timer)
        clearTimeout(status_timer)

      ui.clear_status(function() {
        // status_timer = setTimeout("ui.clear_status()", seconds_to_show * 1000);
        status_timer = setTimeout("ui.clear_status()", 1000);
        $("#status").removeClass("pending good bad").addClass(status + " visible").html(text);//"slide", {}, anime_dur);
        status_shown = true;
      });

    }
  }
}