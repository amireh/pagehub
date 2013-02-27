require([ 'jquery' ], function($) {
  $(function() {
    $(".settings > nav a[href*='" + current_section + "']")
      .addClass("selected")
      .parent()
      .addClass("selected");
      // .append($(".settings > nav .subnav"));
  });
});