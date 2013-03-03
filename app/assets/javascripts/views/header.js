define('views/header',
[
  'hb!header_path.hbs'
], function(PathTmpl) {
  return Backbone.View.extend({
    el: $("#header"),

    templates: {
      path: PathTmpl
    },

    initialize: function(app) {
      this.state = app;

      this.user = app.current_user;
      this.space = app.space;

      this.user.on('change:nickname', this.render, this);
      this.state.on('highlight_nav_section', this.highlight, this);

      if (this.space) {
        this.space.on('sync', this.render, this);
      }

      this.render();
    },

    render: function() {
      var data = {};
      data.user = this.user.toJSON();

      if (this.space) {
        data.space = this.space.toJSON();
        data.space_admin = this.space.is_admin(this.user);
      }

      this.$el.find('#path').html(this.templates.path(data));

      return this;
    },

    highlight: function(section) {
      console.log("highlighting " + section)
      this.$el.find('a#' + section + '_link').addClass('selected');
    }
  });
});