define('views/users/dashboard',
[
  'backbone',
  'jquery',
  'models/user',
  'jquery.gridster',
  'hb!users/dashboard/space.hbs',
  'pagehub'
], function(Backbone, $, User, undefined, SpaceTmpl, UI) {
  return Backbone.View.extend({
    el: $(".gridster"),

    initialize: function(application) {
      this.user = application.current_user;

      var nr_pages = 0;
      this.user.spaces.every(function(s) { nr_pages += parseInt(s.get('nr_pages')); return true; });
      this.nr_pages = nr_pages;

      this.render();
    },

    render: function() {
      UI.status.mark_pending();

      this.$el.find('ul').gridster({
        widget_margins: [24, 10],
        widget_base_dimensions: [148, 180],
        max_size_x: 5,
        max_size_y: 5
      });

      var gridster = $(".gridster ul").gridster().data('gridster');
      gridster.disable();

      this.user.spaces.every(function(space) {
        var dim   = this.weigh(space),
            data  = space.toJSON();

        if (space.get('role') == 'creator')
          data.owned = true;

        if (dim.x > 5)
          dim.x = 5;
        if (dim.y > 2)
          dim.y = 2;

        gridster.add_widget(SpaceTmpl(data), dim.x, dim.y);

        return true;
      }, this);

      $(".gridster [title]").tooltip({ placement: "right" });

      UI.status.mark_ready();
    },

    weigh: function(space) {
      var nr_pages = parseInt(space.get('nr_pages')),
          ratio = (nr_pages / this.nr_pages * 100.0),
          size = Math.ceil(ratio / this.user.spaces.length / 2);

      return { x: size, y: Math.ceil(size / 2) };
    }
  });
})