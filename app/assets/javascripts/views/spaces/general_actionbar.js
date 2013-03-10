define('views/spaces/general_actionbar',
[ 'backbone' ],
function(Backbone) {
  return Backbone.View.extend({
    el: $("#general_actionbar"),

    events: {
      'click #switch_layout': 'switch_layout',
      'click #switch_scrolling': 'switch_scrolling',
      'click #switch_animability': 'switch_animability',
      'click #refresh_editor': 'delegate_refresh_editor'
    },

    initialize: function(data) {
      _.implode(this, data);

      this.elements = {
        switch_layout:      this.$el.find('#switch_layout'),
        switch_scrolling:   this.$el.find('#switch_scrolling'),
        switch_animability: this.$el.find('#switch_animability')
      }

      this.is_fluid     = this.state.current_user.get('preferences.workspace.fluid'),
      this.is_scrolling = this.state.current_user.get('preferences.workspace.scrolling'),
      this.is_animable  = this.state.current_user.get('preferences.workspace.animable');

      this.render();
    },

    render: function() {
      this.elements.switch_layout.toggleClass('selected', this.is_fluid);
      this.elements.switch_scrolling.toggleClass('selected', !this.is_scrolling);
      this.elements.switch_animability.toggleClass('selected', !this.is_animable);

      $("body").toggleClass("fluid", this.is_fluid);
      $("body").toggleClass("no-scroll", !this.is_scrolling);

      return this;
    },

    switch_layout: function() {
      this.is_fluid = !this.is_fluid;

      this.render();

      this.space.trigger('workspace_layout_changed', { fluid: this.is_fluid });
      this.state.trigger('sync_runtime_preferences', {
        preferences: {
          workspace: {
            fluid: this.is_fluid
          }
        }
      });

      return true;
    },

    switch_scrolling: function() {
      this.is_scrolling = !this.is_scrolling;

      this.render();

      this.space.trigger('workspace_layout_changed', { scrolling: this.is_scrolling });
      this.state.trigger('sync_runtime_preferences', {
        preferences: {
          workspace: {
            scrolling: this.is_scrolling
          }
        }
      });

      return true;
    },

    switch_animability: function() {
      this.is_animable = !this.is_animable;

      this.render();

      this.state.trigger('sync_runtime_preferences', {
        preferences: {
          workspace: {
            animable: this.is_animable
          }
        }
      });
    },

    delegate_refresh_editor: function() {
      this.space.trigger('refresh_editor');
    }
  });
})