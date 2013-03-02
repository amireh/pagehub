define(
'views/shared/settings/director',
[
  'backbone',
  'jquery',
  'shortcut',
  'pagehub',
  'models/state'
],
function(Backbone, $, Shortcut, UI, State) {
  return Backbone.View.extend({
    el: $("#settings"),

    type: 'director',

    initialize: function(model, state) {
      var director  = this;
      // _.implode(this, data);

      this.model    = model;
      this.state    = state;
      this.ctx      = {};
      this.views    = [];
      this.aliases  = [];
      this.presync_map = {};

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

    go: function(path) {
      path = '/' + this.model.get('media.url') + path;

      Backbone.history.start({
        pushState: false,
        root: path
      });

      console.log(Backbone.history.root)
      return this;
    },

    add_alias: function(alias) {
      this.aliases.push(alias);
      return this;
    },

    register: function(view_factory, label) {

      if (this.get_view(label)) {
        throw "[director] a view is already registered with label '" + label + "'";
      }

      var data = {
        model:    this.model,
        director: this,
        label:    label,
        ctx:      this.ctx
      };

      _.each(this.aliases, function(alias) { data[alias] = data.model; return true; }, this);

      this.presync_map[label] = [];

      var view = new view_factory(data);

      if (!view.serialize) {
        throw "Missing view#serialize() implementation in view '" + view.label + "'";
      }

      view.on('sync', this.partial_sync, this);

      this.views.push(view);

      this.log("view registered: '" + view.label + "'");

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

    before_sync: function(view, callback) {
      this.presync_map[view.label].push(function() { return callback.apply(view); });

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


      if (this.current_view) {

        if (!this.current_view.is_serializable())
          return false;

        this.log("serializing...");

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
    save: function(no_presync_callbacks) {
      if (this.state.get('syncing')) {
        return null;
      }

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

      return this.sync(data, no_presync_callbacks);
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    sync: function(d, no_presync_callbacks) {
      var director = this,
          state    = this.state;

      if (!no_presync_callbacks) {
        this.ctx.abort_sync = false;

        _.each(this.presync_map[this.current_view.label], function(callback) {
          if (!callback()) {
            director.ctx.abort_sync = true;
            return false;
          }

          return true;
        });

        if (this.ctx.abort_sync) {
          console.log("sync aborted as per a callback's request.");
          return this;
        }
      }

      UI.status.mark_pending();
      director.trigger('presync', director);

      try { // need to make sure not to invalidate our context by leaving 'syncing' on

        if (this.current_view.reset) {
          this.current_view.reset();
        }

        this.state.set('syncing', true);

        this.model.save(d, {
          wait: true,
          patch: true,

          success: function() {
            director.trigger('postsync', director, true);
            UI.status.show("Saved", "good");
          },

          error: function(_, e) {
            director.trigger('postsync', director, false, e);

            try {
              var api_error = JSON.parse(e.responseText);

              if (director.current_view.on_sync_error) {
                var reported = director.current_view.on_sync_error(api_error.field_errors);
                if (reported) {
                  e.__pagehub_no_status = true;
                }
              }

            } catch(err) {
            }
          }
        });

        this.model.fetch({
          success: function() {
            state.set('syncing', false);
            UI.status.mark_ready();

            director.render();
            director.trigger('postfetch', director, director.model, true);
          },
          error: function() {
            state.set('syncing', false);
            UI.status.mark_ready();

            director.trigger('postfetch', director, director.model, false);
          }
        });

      } catch(e) {
        state.set('syncing', false);
      }

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
        this.state.current_director = this;

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