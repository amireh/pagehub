define('helpers/underscore', [ 'underscore' ], function(_) {
  if (!_.implode) {
    _.implode = function(object, data) {
      var data  = data,
          me    = object;

      _.each(_.pairs(data), function(entry) { me[entry[0]] = entry[1]; });

      return me;
    }
  }

  return _;
});