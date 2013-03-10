define('views/spaces/show',
[
  'backbone',
  'views/spaces/workspace/router',
  'views/spaces/resource_actions',
  // 'views/spaces/browser/finder',
  // 'views/spaces/browser/explorer',
  'views/spaces/browser/browser',
  'views/spaces/page_actionbar',
  'views/spaces/general_actionbar',
  'views/spaces/editor',
  'views/spaces/finder',
  'pagehub',
  'timed_operation'
], function(Backbone, Router, ResourceActions, Browser, PageActionBar, GeneralActionBar, Editor, Finder, UI, TimedOp) {
  return Backbone.View.extend({
    initialize: function(state) {
      UI.status.mark_pending();

      this.space = state.space;
      this.state = state;
      this.ctx = {
        settings_changed: false,
        settings: {
          runtime: { collapsed: [ ] }
        }
      }

      var data = {
        state: state,
        space: state.space,
        workspace:  this,
        ctx:        this.ctx
      };

      this.state.workspace = this;

      this.resource_actions = new ResourceActions(data);
      this.browser          = new Browser(data);
      this.editor           = new Editor(data);
      this.page_actionbar   = new PageActionBar($.extend({}, data, { editor: this.editor }));
      this.workspace_actionbar   = new GeneralActionBar(data);
      this.finder   = new Finder(data);

      this.space.folders.on('add', this.track_folder, this);

      this.space.folders.every(function(f) {
        this.space.folders.trigger('add', f);

        f.pages.every(function(p) {
          return this.pages.trigger('add', p);
        }, f);

        return true;
      }, this);

      // this.space.folders.every(function(f) {
      //   return this.space.folders.trigger('change:parent.id', f);
      // }, this);

      state.on('sync_runtime_preferences', this.queue_preferences_sync, this);
      state.on('sync_runtime_preferences_now', this.autosave_preferences, this);

      this.preferences_autosaver = new TimedOp(this, this.autosave_preferences, {
        pulse: state.get('preferences.pulses.runtime_preferences')
      });

      this.space.folders.on('remove', this.reset_if_current_folder, this);

      this.on('load_folder', this.switch_to_folder, this);
      this.on('load_page', this.switch_to_folder_and_load_page, this);
      // this.space.trigger('load_folder', this.space.root_folder());
      this.on('move_folder', this.move_folder, this);
      this.on('move_page',   this.move_page, this);
      this.on('reset', this.reset_context, this);

      UI.status.mark_ready();
    },

    on_invalid_route: function(path) {
      UI.status.show('The resource you requested does not seem to exist anymore.', 'bad');
      // this.space.trigger('load_folder', this.space.root_folder());
      this.state.router.navigate('/', { trigger: true, replace: true });
      return true;
    },

    go: function() {
      this.state.router =  new Router(this, this.space);

      Backbone.history.start({
        pushState:  false,
        root:       this.space.get('media.actions.edit') + '/'
      });

      this.state.trigger('bootstrapped');
    },

    queue_preferences_sync: function(prefs) {
      return this.preferences_autosaver.queue(prefs);
    },

    autosave_preferences: function(prefs, timed_invocation) {
      this.state.current_user.save($.extend({}, prefs, { no_object: true }), {
        patch: true
      })
    },

    // reset the current resource context (and selections)
    reset_context: function() {
      // console.log('[browser] -- resetting context -- ');

      this.current_folder = null;
      this.current_page   = null;

      return this;
    },

    reset_if_current_folder: function(folder) {
      if (this.current_folder == folder) {
        this.trigger('reset');
      }
    },

    track_folder: function(folder) {
      folder.pages.on('change:folder.id', this.reparent_page, this);
      folder.pages.on('remove', this.reset_if_current_page_is_destroyed, this);
    },

    reparent_page: function(page) {
      var new_folder = this.space.folders.get(page.get('folder.id'));

      if (!page.isNew() && page._previousAttributes.folder) {
        var old_folder = this.space.folders.get(page._previousAttributes.folder.id);

        if (!old_folder) {
          UI.report_error("[workspace]: page reparenting failed; unable to locate old folder of page " + page.get('id'));
          return false;
        }

        old_folder.pages.remove(page);
      }

      new_folder.pages.add(page);

      return true;
    },

    switch_to_folder: function(f, silent) {
      // TODO: when does this happen?
      if (!f) {
        UI.report_error("[workspace]: switch_to_folder called with an undefined folder");
        return false;
      }

      var last_folder = this.current_folder;

      // silent is set when a page is being switched to that resides in a
      // folder different than the current one, then an implicit call to
      // switch_to_folder() is made and a 'reset' is also triggered
      if (!silent) {
        this.trigger('reset');
      }

      // TODO: shouldn't this go before the reset?
      if (f == this.current_folder) {
        return this;
      }

      console.log('[workspace] -- switching to folder#' + f.get('id') + ' -> ' + f.get('title') + '--');

      if (last_folder) {
        last_folder.off('change', this.broadcast_current_folder_update, this);
      }

      this.current_folder = f;
      this.current_folder.on('change', this.broadcast_current_folder_update, this);
      this.trigger('folder_loaded', f, last_folder);

      return this;
    },

    switch_to_folder_and_load_page: function(page) {
      var workspace = this;

      console.log('[workspace] -- switching to page#' + page.get('id') + ' -> ' + page.get('title') + ' --');

      workspace.switch_to_folder(page.collection.folder, true);

      if (this.current_page) {
        this.current_page.off('change', this.broadcast_current_page_update, this);
      }

      page.fetch({
        wait: true,
        success: function() {
          workspace.current_page = page;
          workspace.current_page.on('change', workspace.broadcast_current_page_update, workspace);
          workspace.trigger('page_loaded', page);
        }
      });

      return this;
    },

    move_folder: function(folder, new_parent) {
      if (!folder || !new_parent) {
        UI.report_error("bad move folder evt!")
        return false;
      }

      folder.save({ parent_id: new_parent.get('id') }, {
        patch: true,
        wait: true,
        success: function() {
          UI.status.show("Folder moved.", "good");
        }
      });
    },

    move_page: function(page, folder) {
      if (!page || !folder) {
        UI.report_error("bad move page evt!")
        return false;
      }

      page.save({ folder_id: folder.get('id') }, {
        patch: true,
        wait:  true,
        success: function() {
          UI.status.show("Page moved.", "good");
        }
      });
    },

    broadcast_current_folder_update: function(f) {
      this.trigger('current_folder_updated', this.current_folder);
    },

    broadcast_current_page_update: function(page) {
      this.trigger('current_page_updated', page);

      if (page.collection.folder != this.current_folder) {
        return this.switch_to_folder_and_load_page(page);
      }
    },

    reset_if_current_page_is_destroyed: function(page) {
      if (page == this.current_page) {
        this.trigger('reset');
        this.current_folder = page.collection.folder;
      }
    }

  });
})