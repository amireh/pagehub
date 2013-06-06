define('views/shared/settings/nav', [ 'jquery' ], function($) {
  var current_section = current_section || '';
  $(function() {
    $(".settings > nav a[href*='" + current_section + "']")
      .addClass("selected")
      .parent()
      .addClass("selected");
      // .append($(".settings > nav .subnav"));
  });
});