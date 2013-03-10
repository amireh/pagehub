define('views/spaces/workspace/router',
[
  'backbone'
], function(Backbone) {

  $(document).on("dblclick", "#browser a.selected", function(evt) {
    evt.preventDefault();
    evt.stopPropagation();
    evt.stopImmediatePropagation();
    // console.log("navigating to page...");
    Backbone.history.navigate($(this).attr("href"), { silent: false, trigger: true });
    return false;
  });

  // $(document).on("dblclick", "#browser a[data-href].selected", function(evt) {
  //   evt.preventDefault();
  //   Backbone.history.navigate($(this).attr("data-href"), true);
  // });

  $(document).on("click", "#path a[href^=#]", function(evt) {
    evt.preventDefault();
    Backbone.history.navigate($(this).attr("href"), { silent: false, trigger: true });
  });

  var UserSettingsRouter = Backbone.Router.extend({

    routes: {
      "":  "root_folder",
      "*notFound": "resource"
    },

    initialize: function(director, space) {
      this.director = director,
      this.space    = space;

      this.director.on('current_page_updated', this.update_current_history_state, this);
    },

    update_current_history_state: function(page) {
      console.log("[router]: updating path")
      Backbone.history.navigate(page.ctx.browser.anchor.attr('href'), { silent: false })
    },

    root_folder: function() {
      this.director.trigger('load_folder', this.space.root_folder());
    },

    proxy_resource: function(resource) {
      return Backbone.history.navigate(resource.path(), { trigger: true })
    },

    resource: function(path) {
      var parts     = path.trim().split('/'),
          title     = _.last(parts),
          folder    = this.space.root_folder(),
          resource  = null,
          routed    = false;

      // console.log("navigating to " + path)

      if (title.length == 0) {
        return this;
      }

      if (parts.length > 1) {
        for (var i = 0; i < parts.length - 1; ++i) {
          var folder_title = parts[i];
          var child = this.space.folders.where({ pretty_title: folder_title, 'parent.id': folder.get('id') })[0];

          if (!child) {
            console.log('routing failed; no such folder with title ' + folder_title + ' in parent ' + folder.get('id'))
            this.director.on_invalid_route(path);
            return this;
          }

          folder = child;
        }
      }

      if (!folder) {
        return this;
      }

      // console.log('looking up resource: ' + title + " in folder: " + folder.get('id'));

      // is it a page?
      resource = folder.pages.where({ pretty_title: title })[0];

      if (resource) {
        // console.log('found page, navigating...');
        this.director.trigger('load_page', resource);
      } else {
        // is it a folder?
        resource = this.space.folders.where({ pretty_title: title, 'parent.id': folder.get('id') })[0];

        if (resource) {
          // console.log('found folder, navigating...');
          this.director.trigger('load_folder', resource);
        } else {
          console.log('routing failed; unable to find resource titled ' + title + ' in folder ' + folder.get('id'));
          this.director.on_invalid_route(path);
        }
      }

      return this;
    }

  });

  return UserSettingsRouter;
})