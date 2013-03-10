define('views/spaces/finder',
[ 'animable_view', 'pagehub', 'shortcut' ],
function(AnimableView, UI, Shortcut) {
  return AnimableView.extend({
    el: $("#page_finder"),

    events: {
    },

    initialize: function(data) {
      var view = this;

      _.implode(this, data);

      Shortcut.add("ctrl+alt+p", function() { view.show(); })

      // this.finder.siblings('.btn').on('click', function() { return view.show(); })
      this.container = this.$el.parents('.page-finder:first');

      this.page_titles = [];

      this.state.on('actionbar_hidden', this.do_show_finder, this);
      this.workspace.on('reset', this.hide, this);
      this.workspace.on('page_loaded', this.hide, this);
      this.space.folders.on('add', this.track_folder_pages, this);
      this.bind_finder();

      this.hide();
    },

    hide: function() {
      var me = this;

      if (!this.shown())
        return;

      if (this.animable()) {
        this.container.hide("slide", {}, this.anime_length, function() {
          me.state.trigger("finder_hidden");
        });
      } else {
        this.container.hide();
        this.state.trigger("finder_hidden");
      }
    },

    show: function() {
      if (this.shown()) {
        this.$el.focus();
        return;
      }

      this.state.trigger('hide_actionbar');

      return true;
    },

    shown: function() {
      return this.container.is(":visible");
    },

    do_show_finder: function() {
      // this.state.trigger("finder_shown");

      if (this.animable()) {
        this.container.show("slide", {}, this.anime_length);
      } else {
        this.container.show();
      }

      this.$el.focus();
    },

    bind_finder: function() {
      var finder = this;

      this.$el.typeahead({
        source: finder.page_titles,

        updater: function(fqpt, item) {
          finder.switch_to_page(item.attr("data-page"), item.attr("data-folder"));
          return null;
        },

        on_escape: function() {
          finder.$el.val('');
          finder.hide();

          return true;
        },

        label_extractor: function(item) {
          return item.label;
        },

        formatter: function(item, el) {
          $(el).attr('data-folder', item.folder_id);
          $(el).attr('data-page', item.page_id);
        }
      });
    },

    switch_to_page: function(page_id, folder_id) {
      var page = this.find_page_in_folder(folder_id, page_id);

      if (!page) {
        UI.status.show("Could not find the page you were looking for.", "bad");
        return false;
      }

      // this.workspace.trigger('load_page', page);
      this.state.router.proxy_resource(page);

      return true;
    },

    track_folder_pages: function(folder) {
      folder.on('change:title', this.update_tracked_folder_title, this);
      folder.pages.on('add', this.track_page_title, this);
      folder.pages.on('remove', this.stop_tracking_page_title, this);
      folder.pages.on('change:title', this.update_tracked_page_title, this);
    },

    track_page_title: function(page) {
      // console.log("tracking page: " + page.get('id'))

      this.page_titles.push({
        label:      this.labelize(page),
        folder_id:  page.folder.get('id'),
        page_id:    page.get('id')
      });

      page.ctx.finder_index = this.page_titles.length - 1;

      return true;
    },

    stop_tracking_page_title: function(page) {
      // console.log("no longer tracking page: " + page.get('title') + '@' + page.ctx.finder_index);

      if (!page.ctx.finder_index) {
        return UI.report_error("Page context is missing finder index, I can't un-track it!");
      }

      this.page_titles.splice( page.ctx.finder_index, 1 );

      return true;
    },

    labelize: function(page) {
      return page.fully_qualified_title().join(' > ');
    },

    find_page_in_folder: function(folder_id, page_id) {
      var folder = this.space.folders.get(folder_id);
      if (!folder) { return null; }
      return folder.pages.get(page_id);
    },

    update_tracked_folder_title: function(folder) {
      var affected_entries = _.where(this.page_titles, { folder_id: folder.get('id') });
      _.each(affected_entries, function(entry) {
        entry.label = this.labelize(this.find_page_in_folder(entry.folder_id, entry.page_id));
        return true;
      }, this);
    },

    update_tracked_page_title: function(page) {
      if (!page.ctx.finder_index) {
        return UI.report_error("Page context is missing finder index, I can't un-track it!");
      }

      this.page_titles[page.ctx.finder_index].label = this.labelize(page);

      return true;
    }

  })
})