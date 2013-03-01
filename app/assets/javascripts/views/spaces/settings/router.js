define('views/spaces/settings/router',
[
  'backbone'
], function(Backbone) {

  var SpaceSettingsRouter = Backbone.Router.extend({

    routes: {
      "": "initial_section",
      ":section": "load_section",
      ":section/:subsection": "load_subsection"
    },

    initialize: function(view, initial_section) {
      this.view            = view;
      this.initial_section = initial_section;
    },

    initial_section: function() {
      return this.view.trigger('section_changed', this.initial_section);
    },

    load_section: function(section) {
      return this.view.trigger('section_changed', section);
    },

    load_subsection: function(section, subsection) {
      return this.view.trigger('section_changed', section + '/' + subsection);
    }
  });

  return SpaceSettingsRouter;
})