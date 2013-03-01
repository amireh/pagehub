define(
'views/shared/settings/director',
[
  'backbone',
  'jquery',
  'shortcut',
  'pagehub'
],
function(Backbone, $, Shortcut, UI) {
  return Backbone.View.extend({
    el: $("#settings"),

    type: 'director',

    initialize: function(data) {
      var director      = this;

      this.space    = data.space;
      this.model    = this.space;
      this.ctx      = data.ctx || {};
      this.views    = [];

      this.on('section_changed',  this.sections.show, this);
      this.on('section_changed',  this.sections.highlight, this);

      $(document).on('submit', function(e) {
        return director.consume(e);
      });

      this.render();
    },

    log: function(msg, blank) {

      if (blank) {
        console.log('[' + this.label + ']');
        console.log(msg);
      } else {
        console.log('[' + this.label + '] ' + msg);
      }

      return this;
    },

    set_router: function(router_factory, entry_point) {
      this.router = new router_factory(this, entry_point);
      return this;
    },

    go: function(root) {
      Backbone.history.start({
        pushState: false,
        root: root
      });
    },

    register: function(view_factory, label) {
      var view = new view_factory({ space: this.space, ctx: this.ctx });
          view.label = label;
          view.director = this;

      if (!view.serialize) {
        throw "Missing view#serialize() implementation in view '" + view.label + "'";
      }

      view.on('sync', this.partial_sync, this);

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

      this.$el.show();

      return this;
    },

    hide: function() {
      return this;
    },

    /**
     * Restore the view to its original state (as in #bootstrap -> #render).
     */
    reset: function() {
      this.$el.hide();

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

      this.log("serializing...");

      if (this.current_view) {
        data = this.current_view.serialize();
        if (!data) {
          console.log("Aborting settings sync; view '" + this.current_view.label + "' failed to serialize.");
          data = null;
          return false;
        }
      } else {
        return false;
      }

      // _.each(this.views, function(view) {
      //   var view_data = view.serialize();


      //   return data = $.extend(true, view_data, data);
      // }, this);

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

      if (!this.current_view)
        return null;

      var data = this.serialize();

      if (!data) {
        return null;
      }

      return this.sync(data);
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    sync: function(d) {
      var view = this;

      UI.status.mark_pending();

      this.space.save(d, {
        wait: true,
        patch: true,
        success: function() {
          UI.status.show("Saved", "good");
        }
      });

      this.space.fetch({
        success: function() {
          view.render();
          UI.status.mark_ready();
        }
      });

      return this;
    },

    partial_sync: function(data, options) {
      this.model.save(data, $.extend(true, options, { patch: true, wait: true }));
      return this;
    },

    get_view: function(label) {
      return _.select(this.views, function(v) {
        if (v.type == 'director' && v.get_view(label)) {
          return [ v.get_view(label) ];
        }

        return v.label == label;
      })[0];
    },

    sections: {
      show: function(view_label) {
        var view = this.get_view(view_label);

        this.log("showing view: " + view_label);

        if (!view) {
          throw "Undefined view with label '" + view_label + "'";
        }

        _.each(this.views, function(view) { view.hide(); return true; });

        view.render();
        this.current_view = view;
        this.ctx.current_director = this;

        return true;
      },

      highlight: function(label) {
        if (!this.nav)
          return true;

        this.nav.
        find('.selected').removeClass('selected').end().
        find('a[href="' + label + '"]').parent().addClass('selected');

        return true;
      },
    }
  });
});