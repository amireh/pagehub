define('views/users/dashboard/director',
[
  'backbone',
  'jquery',
  'models/user',
  'jquery.gridster',
  'hbs!templates/users/dashboard/space_record',
  'pagehub'
], function(Backbone, $, User, undefined, SpaceTmpl, UI) {
  return Backbone.View.extend({
    el: $("#dashboard"),

    initialize: function(application) {
      this.state = application;
      this.user  = application.user;

      var nr_pages = 0;
      this.user.spaces.every(function(s) { nr_pages += parseInt(s.get('nr_pages')); return true; });
      this.nr_pages = nr_pages;
      this.space_listing = this.$el.find('#user_space_listing');
      this.empty_listing_marker = this.$el.find('#no_spaces_marker');

      this.render();
      this.state.trigger('bootstrapped');
    },

    render: function() {
      // UI.status.mark_pending();

      // this.$el.find('ul').gridster({
      //   widget_margins: [10, 20],
      //   widget_base_dimensions: [130, 200],
      //   max_size_x: 3,
      //   max_size_y: 2
      // });

      // var gridster = $(".gridster ul").gridster().data('gridster');
      // gridster.disable();

      // this.user.spaces.every(function(space) {
      //   var dim   = this.weigh(space),
      //       data  = space.toJSON();

      //   if (space.get('role') == 'creator')
      //     data.owned = true;

      //   if (dim.x > 3)
      //     dim.x = 3;
      //   if (dim.y > 2)
      //     dim.y = 2;

      //   gridster.add_widget(SpaceTmpl(data), dim.x, dim.y);

      //   return true;
      // }, this);

      // $(".gridster [title]").tooltip({ placement: "right" });

      // UI.status.mark_ready();

      this.empty_listing_marker.toggle(this.user.spaces.models.length == 0);

      this.user.spaces.every(function(space) {
        var data  = space.toJSON();

        if (space.get('role') == 'creator')
          data.is_owner = true;
        else if(space.get('role') != null)
          data.is_member = true;
        else
          data.is_guest  = true;

        if (data.brief.length == 0) {
          data.brief = null;
        }

        this.space_listing.append(SpaceTmpl(data));

        return true;
      }, this);

    },

    weigh: function(space) {
      var nr_pages = parseInt(space.get('nr_pages')),
          ratio = (nr_pages / this.nr_pages * 100.0),
          size = Math.ceil(ratio / this.user.spaces.length / 2);

      return { x: size, y: Math.ceil(size) };
    }
  });
})