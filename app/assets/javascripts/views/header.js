define('views/header',
[
  'hbs!templates/header_path'
], function(PathTmpl) {
  return Backbone.View.extend({
    el: $("#header"),

    templates: {
      path: PathTmpl
    },

    initialize: function(app) {
      this.state = app;

      if (app.space) { // editing a space?
        this.space      = app.space;
        this.user       = app.space.creator;

        this.space.on('sync', this.render, this);
      } else if (app.user) { // dashboard? profile?
        this.user = app.user;
      } else {
        if (app.current_user) {
          this.user = app.current_user;
        }
      }

      if (this.user && app.current_user == app.user) { // current user sections
        this.user.on('change:nickname', this.render, this);
        this.user.on('sync', this.render, this);
      }

      this.state.on('bootstrapped', function() {
        if (app.workspace) {
          this.workspace  = app.workspace;

          app.workspace.on('folder_loaded', this.render, this);
          app.workspace.on('current_folder_updated', this.render, this);
          app.workspace.on('page_loaded',   this.render, this);
          app.workspace.on('current_page_updated', this.render, this);
        }

        this.render();
      }, this);

      this.state.on('highlight_nav_section', this.highlight, this);
    },

    render: function(additional_data) {
      var data = {};

      if (this.user) {
        data.user = {
          nickname: this.user.get('nickname'),
          media:    this.user.get('media')
        }
      }

      if (this.space) {
        data.space = {
          title: this.space.get('title'),
          media: this.space.get('media')
        };

        data.space_admin = this.space.is_admin(this.state.current_user);

        if (this.workspace) {
          if (this.workspace.current_page) {
            $.extend(true, data, this.build_page_path() || {});
          } else if (this.workspace.current_folder) {
            $.extend(true, data, this.build_folder_path() || {});
          }
        }
      }

      this.$el.find('#path').html(this.templates.path(data));

      return this;
    },

    highlight: function(section) {
      this.$el.find('a#' + section + '_link').addClass('selected');
    },

    folder_hierarchy: function(folder) {
      if (!folder.has_parent()) { return []; }
      var folders = _.reject(folder.ancestors(), function(f) { return !f.has_parent(); });

      return folders.reverse();
    },

    build_folder_path: function(data) {
      var folder = this.workspace.current_folder;

      if (!folder) {
        return false;
      }

      console.log('[header] showing folder path')

      // console.log("rendering folder path: " + folder.path())
      return $.extend(true, {
        folders: _.collect(
          this.folder_hierarchy(folder),
          function(f) {
            return {
              title: f.get('title'),
              path:  f.path()
            }
          })
      }, data || {});
    },

    build_page_path: function() {
      var page = this.workspace.current_page;

      if (!page) {
        return false;
      }

      console.log("[header] rendering page path: " + page.path())

      return this.build_folder_path({
        page: {
          title: page.get('title'),
          path: page.path()
        }
      });
    }
  });
});