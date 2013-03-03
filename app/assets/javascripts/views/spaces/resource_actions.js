define('views/spaces/resource_actions',
[ 'backbone', 'models/folder', 'pagehub', 'shortcut' ],
function(Backbone, Folder, UI, Shortcut) {
  return Backbone.View.extend({
    el: $("#pages .actions"),

    events: {
      'click #new_page':    'create_page',
      'click #new_folder':  'create_folder'
    },

    initialize: function(data) {
      var view = this;

      _.implode(this, data);

      this.$el.find('#new_page').attr("href", this.space.get('media').pages.url + '/new');

      Shortcut.add("ctrl+alt+c", function() { view.create_page(); })
      Shortcut.add("ctrl+alt+f", function() { view.create_folder(); })
      Shortcut.add("ctrl+alt+p", function() { view.show_page_finder(); })

      this.finder = $('#page_finder');
      this.finder.siblings('.btn').on('click', function() { return view.show_page_finder(); })

      this.page_titles = [];

      this.space.folders.on('add', this.track_folder_pages, this);
      this.bind_finder();
    },

    bind_finder: function() {
      var view = this;

      this.finder.typeahead({
        source: view.page_titles,

        updater: function(item) {
          view.switch_to_page(_.unescape(item));
          return null;
        }
      });
    },

    create_page: function(e) {
      if (e) { e.preventDefault(); }

      // UI.status.show("Creating a new page...", "pending");
      var folder  = this.ctx.current_folder || this.space.root_folder();

      folder.pages.add({ folder_id: folder.get('id') }, { silent: true });
      var page = _.last(folder.pages.models);

      page.save({}, {
        success: function() {
          page.collection.trigger('add', page);
          UI.status.show("Created!", "good");
        }
      })
      // this.space.trigger('load_page', page);

      return false;
    },

    create_folder: function(e) {
      if (e) { e.preventDefault(); }

      // ui.status.show("Creating a new folder...", "pending");

      var parent  = this.ctx.current_folder || this.space.root_folder(),
          space   = parent.collection.space,
          view    = this;

      $.ajax({
        type:   "GET",
        headers: { Accept: "text/html" },
        url:    space.get('media').folders.url + '/new',
        success: function(dialog_html) {
          var dialog = $('<div>' + dialog_html + '</div>').dialog({
            title: "Creating a folder",
            width: 'auto',

            // select the current folder from the parent folder list for convenience
            open: function() {
              $(this)
              .find('select :selected').attr("selected", false).end()
              .find("select option[value=" + parent.get('id') + "]").attr("selected", true).end()
              .find('form').on('submit', view.consume);
            },

            buttons: {
              Cancel: function() {
                $(this).dialog("close");
              },
              Create: function(e) {
                var folder_data = dialog.find('form').serializeObject();
                space.folders.add(folder_data, { silent: true });
                var folder = _.last(space.folders.models);

                folder.save({}, {
                  wait: true,
                  success: function(f) {
                    UI.status.show("Folder created!", "good");
                    f.collection.trigger('add', f);
                    dialog.dialog("close");
                  }
                });
                e.preventDefault();
              }
            }
          });
        }
      });

      return false;
    },

    switch_to_page: function(fqpt) {
      var page = this.space.find_page_by_fully_qualified_title(fqpt.split(' > '));

      if (!page) {
        UI.status.show("Could not find the page you were looking for.", "bad");
        return false;
      }

      this.space.trigger('reset');
      this.space.trigger('load_page', page);

      return true;
    },

    show_page_finder: function() {
      this.finder.focus();

      return true;
    },

    track_folder_pages: function(folder) {
      folder.pages.on('add', this.track_page_title, this);
      folder.pages.on('remove', this.stop_tracking_page_title, this);

    },

    track_page_title: function(page) {
      console.log("tracking page: " + page.get('id'))

      this.page_titles.push( page.fully_qualified_title().join(' &gt; ') );
      page.ctx.finder_index = this.page_titles.length - 1;

      return true;
    },

    stop_tracking_page_title: function(page) {
      console.log("no longer tracking page: " + page.get('title') + '@' + page.ctx.finder_index);

      if (!page.ctx.finder_index) {
        return UI.report_error("Page context is missing finder index, I can't un-track it!");
      }

      this.page_titles.splice( page.ctx.finder_index, 1 );

      return true;
    }

  })
})