require([ 'jquery' ], function($) {
  $(function() {
    if ($(".subnav").children().length > 1) {
      $(".settings .subnav a[href='" + request.path + "']")
        .addClass("selected")
        .parent()
        .addClass("selected");

      $(".settings").addClass("with_subnav");
    }

    var selection_path = request.path;

    if ($(".settings .subnav .selected").length > 0) {
      selection_path = selection_path.split('/').slice(0,-1).join('/');
    }

    $(".settings nav a[href='" + selection_path + "']")
      .addClass("selected")
      .parent()
      .addClass("selected")
      .append($(".settings > nav .subnav"));
  });
});