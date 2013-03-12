define('pagehub.config', [ 'jquery', 'jquery.tinysort' ], function($) {
  $.ajaxSetup({
    headers: {
      Accept : "application/json; charset=utf-8",
      "Content-Type": "application/json; charset=utf-8"
    }
  });

  // jQuery TinySort
  $.tinysort.defaults.sortFunction = function(a,b) {
    var atext = a.e.text().trim(),
        btext = b.e.text().trim();

    return atext === btext ? 0 : (atext > btext ? 1 : -1);
  };

  return {};
});