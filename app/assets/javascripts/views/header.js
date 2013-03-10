define('views/header',
[
  'hb!header_path.hbs'
], function(PathTmpl) {
  return Backbone.View.extend({
    el: $("#header"),

    templates: {
      path: PathTmpl
    },

    initialize: function(app) {
      this.state = app;


      if (app.space) { // editing a space?
        this.space = app.space;
        this.user  = app.space.creator;
        this.space.on('sync', this.render, this);
        this.space.on('load_folder', this.show_folder_path, this);
        this.space.on('load_page',   this.show_page_path, this);
        this.space.on('current_page_updated', this.show_page_path, this);

        // this.state.on('change:current_page', this.proxy_show_page_path, this);
      } else if (app.user) { // dashboard? profile?
        this.user = app.user;

      } else { // current user sections
        this.user = app.current_user;
        this.user.on('change:nickname', this.render, this);
      }

      this.state.on('highlight_nav_section', this.highlight, this);

      this.render();
    },

    render: function(additional_data) {
      var data = {};
      data.user = {
        nickname: this.user.get('nickname'),
        media:    this.user.get('media')
      }

      if (this.space) {
        data.space = {
          title: this.space.get('title'),
          media: this.space.get('media')
        };

        data.space_admin = this.space.is_admin(this.user);
      }

      $.extend(true, data, additional_data || {});

      console.log(data);

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

    show_folder_path: function(folder, data) {
      if (!folder) { return false; }
      if (!this.state.view) return true;
      // console.log("rendering folder path: " + folder.path())
      return this.render($.extend(true, {
        folders: _.collect(
          this.folder_hierarchy(folder),
          function(f) {
            return {
              title: f.get('title'),
              path:  f.path()
            }
          })
      }, data || {}));
    },

    proxy_show_page_path: function(page) {
      console.log(page);
    },

    show_page_path: function(page) {
      if (!page) { return false; }
      console.log(page)
      // console.log("rendering page path: " + page.path())
      return this.show_folder_path(page.folder, {
        page: { title: page.get('title'), path: page.path() }
      });
    }
  });
});