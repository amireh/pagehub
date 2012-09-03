$(function() {
  var colour_scheme_map = 
    [ "Background", "Foreground", "Heading #1", "Heading #2", "Heading #3 and Links" ];

  $("span.scheme_colours").hover(function() {
    var idx = $(this).attr("class").substr(-1);
    // $(this).addClass("zoom").html(colour_scheme_map[idx]);
    $("#colour_explanation").html("Colour: " + colour_scheme_map[idx]);
  }, function() {
    $("#colour_explanation").html("Colour: &minus;");      
    // $(this).removeClass("zoom").html("");
  });

  ui.editor = editor = ui.create_editor("preview_editor", {
    readOnly: true
  });

  $("input[type=radio][name*=editing]").change(function() { 
    var ff = $(this).parent().css("font-family");
    console.log(ff)
    $(".CodeMirror").css("font-family", ff);
  });
  $("input[type=text][name*=editing\\\]\\\[font_size]").keyup(function(e) {
    if (e.keyCode == 38) { $(this).attr("value", parseInt($(this).attr("value")) + 1);}
    else if (e.keyCode == 40) { $(this).attr("value", parseInt($(this).attr("value")) - 1);}
    $(".CodeMirror").css("font-size", parseInt($(this).attr("value") || 1) + "px");
  });
  $("input[type=text][name*=editing\\\]\\\[line_height]").keyup(function(e) {
    if (e.keyCode == 38) { $(this).attr("value", parseInt($(this).attr("value")) + 1);}
    else if (e.keyCode == 40) { $(this).attr("value", parseInt($(this).attr("value")) - 1);}
    $(".CodeMirror").css("line-height", parseInt($(this).attr("value") || 1) + "px");
  });
  $("input[type=text][name*=editing\\\]\\\[letter_spacing]").keyup(function(e) {
    if (e.keyCode == 38) { $(this).attr("value", parseInt($(this).attr("value")) + 1);}
    else if (e.keyCode == 40) { $(this).attr("value", parseInt($(this).attr("value")) - 1);}
    $(".CodeMirror").css("letter-spacing", parseInt($(this).attr("value") || 0) + "px");
  });

});
