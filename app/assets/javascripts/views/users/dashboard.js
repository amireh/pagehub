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
        
    initialize: function(data) {
      this.user = new User(data.user);
      this.ctx = data.ctx || {};
      this._ctx = {}
      
      var nr_pages = 0;
      this.user.spaces.every(function(s) { nr_pages += parseInt(s.get('nr_pages')); return true; });
      this._ctx.nr_pages = nr_pages;
      
      this.render();
    },
    
    render: function() {
      this.$el.find('ul').gridster({
        widget_margins: [24, 10],
        widget_base_dimensions: [148, 180]
      });
      
      var gridster = $(".gridster ul").gridster().data('gridster');
      
      gridster.disable();
      
      this.user.spaces.every(function(space) {
        var weight = this.weigh(space);
        var data = space.toJSON();
        
        if (space.get('role') == 'creator')
          data.owned = true;
        
        gridster.add_widget(SpaceTmpl(data), weight[0], weight[1]);
        return true;
      }, this);
      
      $(".gridster [title]").tooltip({ placement: "right" });
    },
    
    weigh: function(space) {
      var nr_pages = parseInt(space.get('nr_pages')),
          ratio = (nr_pages / this._ctx.nr_pages * 100.0),
          size = Math.ceil(ratio / this.user.spaces.length / 2);
      // console.log("Space " + space.get('title') + " has " + ratio + "% of the total user pages (" + Math.ceil(ratio / this.user.spaces.length) + ")");
      return [ size, Math.ceil(size / 2) ];
    }
  });
})