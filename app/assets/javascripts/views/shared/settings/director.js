define(
'views/shared/settings/director',
[
  'backbone',
  'jquery',
  'shortcut'
],
function(Backbone, $, Shortcut) {
  return Backbone.View.extend({
    el: $("#settings"),

    events: {
      'click [data-role=save]': 'save'
    },

    initialize: function(data) {
      var view      = this;

      this.space    = data.space;
      this.ctx      = data.ctx || {};
      this.views    = [];

      this.on('settings_changed', this.save)
      this.on('section_changed',  this.sections.show, this);
      this.on('section_changed',  this.sections.highlight, this);

      Shortcut.add("ctrl+alt+s", function() { view.save(); });
      Shortcut.add("ctrl+alt+v", function() { window.open(view.space.get('media.href'), '_preview'); });

      $(document).on('submit', function(e) {
        view.consume(e);
      });
    },

    register: function(view_factory, label) {
      var view = new view_factory({ space: this.space, ctx: this.ctx });
          view.label = label;

      if (!view.serialize) {
        throw "Missing view#serialize() implementation in view '" + view.label + "'";
      }

      this.views.push(view);
      return this;
    },

    load: function() {
    },

    /**
     * Do any resource allocation here. This will be called only *once*
     * during the view lifetime.
     */
    bootstrap: function() {
      return this;
    },

    /**
     * Render the view!
     *
     * @note Does an implicit call to #reset()
     */
    render: function() {
      if (this.reset) {
        this.reset();
      }

      return this;
    },

    /**
     * Restore the view to its original state (as in #bootstrap -> #render).
     */
    reset: function() {
      return this;
    },

    /**
     * Carry out any necessary transformation of the data in the
     * view/HTML and convert it to the JSON that will be synced
     * with the server model.
     *
     * @return a hash of the fully-qualified serialized data
     */
    serialize: function() {
      var data = {};

      _.each(this.views, function(view) {
        var view_data = view.serialize();

        if (!view_data) {
          console.log("Aborting settings sync; view '" + view.label + "' failed to serialize.");
          data = null;
          return false;
        }

        return data = $.extend(true, view_data, data);
      }, this);

      return data;
    },

    /**
     * Sync settings with the server model.
     *
     * This will be invoked everytime a 'settings_changed' event is triggered,
     * and it will internally call #serialize() before saving.
     *
     * You *MUST* define this in the main setting view for the settings to be stored!
     */
    save: function() {
      if (!this.sync) {
        throw "Missing director#sync() implementation!";
      }

      if (!this.serialize) {
        throw "Missing director#serialize() implementation!";
      }

      var data = this.serialize();

      if (!data) {
        return this;
      }

      return this.sync(data);
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    // sync: function(serialized_data) {
    //   return this;
    // },

    sections: {
      show: function(view_label) {
        var view = _.select(this.views, function(v) { return v.label == view_label })[0];

        if (!view) {
          throw "Undefined view with label '" + view_label + "'";
        }

        _.each(this.views, function(view) { view.$el.hide("blind"); });

        view.$el.show("blind");
        view.render();

        return true;
      },

      highlight: function(view_label) {
        var target = (view_label.indexOf('/') != -1) ? this.subnav : this.nav;

        target.
        find('.selected').removeClass('selected').end().
        find('a[href=' + view_label + ']').parent().addClass('selected');

        return true;
      },
    }
  });
});