define('views/spaces/general_actionbar',
[ 'backbone' ],
function(Backbone) {
  return Backbone.View.extend({
    el: $("#general_actionbar"),

    events: {
      'click #switch_layout': 'switch_layout'
    },

    initialize: function(data) {
      _.implode(this, data);

      this.elements = {
        switch_layout: this.$el.find('#switch_layout')
      }

      this.is_fluid = this.user.get('preferences.runtime.fluid_workspace');
      this.render();
    },

    render: function() {
      this.elements.switch_layout.toggleClass('selected', this.is_fluid);
      $("body").toggleClass("fluid", this.is_fluid);

      return this;
    },

    switch_layout: function() {
      this.is_fluid = !this.is_fluid;

      this.render();

      this.space.trigger('layout_changed', { fluid: this.is_fluid });
      this.state.trigger('sync_runtime_preferences', { preferences: { runtime: { fluid_workspace: this.is_fluid } } });

      return true;
    }
  });
})