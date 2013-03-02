define('models/state',
  [ 'backbone', 'backbone.nested' ],
  function(Backbone) {

  var State = Backbone.DeepModel.extend({
    initialize: function(data) {
      return _.implode(this, data || {});
    }
  });

  return State;
});