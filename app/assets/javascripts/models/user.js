define('models/user',
  [ 'jquery', 'underscore', 'backbone', 'collections/spaces', 'backbone.nested' ],
  function($, _, Backbone, Spaces) {

  var User = Backbone.DeepModel.extend({
    defaults: {
      nickname: "",
      email:    "",
      spaces:   null,
      preferences: {}
    },

    urlRoot: function() {
      return '/users';
    },

    parse: function(data) {
      return data.user;
    },

    initialize: function(data) {
      this.ctx = {};

      this.spaces = new Spaces(data.spaces);
      this.spaces.creator = this;
    }
  });

  return User;
});