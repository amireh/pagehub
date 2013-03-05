define('views/spaces/finderlike_browser',
[
  'jquery',
  'backbone',
  'views/spaces/browser/drag_manager',
  'views/spaces/browser/actionbar',
  'hb!browser/folder.hbs',
  'hb!browser/page.hbs',
  'hb!dialogs/destroy_folder.hbs',
  'pagehub'
],
function( $, Backbone, DragManager, ActionBar, FolderTemplate, PageTemplate, DestroyFolderTmpl, UI ) {

  return Backbone.View.extend({
    el: $("#browser"),

    templates: {
      folder: FolderTemplate,
      page:   PageTemplate
    },

    events: {
      'click .folder_title a:not(.selected)': 'proxy_highlight_folder',
    },

    initialize: function(data) {
      var view = this;

      _.implode(this, data);

      this.offset = 135;

      $(window).on('resize', function() { return view.resize(); });

      this.space.on('load_folder',  this.switch_to_folder, this);
      this.space.on('load_page',    this.fetch_page, this);
      this.space.on('page_loaded',  this.highlight, this);
      this.space.on('page_loaded',  this.focus, this);
      this.space.on('page_created', this.on_page_loaded, this);
      this.space.on('reset', this.reset, this);
      this.space.folders.on('add', this.render_folder, this);
      this.space.folders.on('remove', this.remove_folder, this);
      this.space.folders.on('change:title', this.update_title, this);
      this.space.folders.on('change:title', this.reorder_folder, this);
      this.space.folders.on('change:parent.id', this.reorder_folder, this);

      // this.drag_manager = new DragManager(data);
      this.actionbar = new ActionBar(data);

      this.elements = {
        scroller: $("#browser_scroller"),
        go_up: $("#goto_parent_folder")
      }

      this.$el.addClass('finder-like').parent().addClass('finder-like');

      this.bootstrap();
    },


    bootstrap: function() {
      this.resize();

      return this;
    },

    pass: function(e) {
    //   // e.propagateEvent();
      return true;
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    reset: function() {
      this.$el.find('.selected').removeClass('selected');
      this.ctx.selected_folder = null;
      // this.ctx.current_folder = null;
      // this.ctx.current_page   = null;
    },

    resize: function() {
      if (this.state.current_user.get('preferences.runtime.scrolly_workspace')) {
        $("#pages .scroller").css("max-height", $(window).height() - 135);
      }
    },

    folder_from_title: function(el) {
      var folder_el = $(el).parents(".folder:first"),
          id        = null;

      if (folder_el.attr('data-folder')) {
        id = folder_el.attr('data-folder');
      } else if (folder_el.attr('id')) {
        id = folder_el.attr("id").replace('folder_', '');
      }

      console.log('looking up folder id from element: ' + id);

      return this.space.folders.get( id );
    },

    proxy_switch_to_folder: function(evt) {
      var el      = (evt.target),
          folder  = this.folder_from_title(el);

      this.space.trigger('load_folder', folder);
      // console.log(el)
      // this.state.router.resource($(el).attr('href').substr(1));

      return true;
    },

    switch_to_folder: function(f) {
      if (!f) {
        return false;
      }

      this.space.trigger('reset');

      if (f == this.ctx.current_folder) {
        return false;
      }

      console.log("switching to folder: " + f.get('title') + '#' +f.get('id'))

      // this.reset();
      this.$el.find('.folder').hide();

      if (this.ctx.current_folder) {
        var last_folder = this.ctx.current_folder,
            its_parent  = last_folder.get_parent();

        last_folder.trigger('change:parent.id', last_folder);
        last_folder.ctx.browser.title_container.show();
      }

      this.$el.append(f.ctx.browser.el);

      f.ctx.browser.title_container.hide();

      _.each(this.space.folders.where({ 'parent.id': f.get('id') }), function(cf) {
        cf.ctx.browser.el.show();
        cf.ctx.browser.page_listing.hide();
        return true;
      });

      if (f.has_parent()) {
        this.elements.go_up
          .show().attr('data-folder', f.get_parent().get('id'))
          .find('a').attr('data-href', '#' + f.get_parent().path());

        f.ctx.browser.folder_listing.show().prepend(this.elements.go_up);
      }

      f.ctx.browser.page_listing.show();
      f.ctx.browser.el.show("drop", {}, 250);

      this.ctx.current_folder = f;

      return true;
    },

    render_folder: function(f) {
      var folder_data = this.resource_data(f),
          entry   = this.templates.folder(folder_data),
          target  = this.$el,
          el      = target.append( entry ).children().last();

      f.ctx.browser = {
        el:             el,
        title_container: el.find('.folder_title'),
        title:          el.find('.folder_title > a'),
        folder_listing: el.find('ol.folders'),
        collapser:      el.find('button[data-collapse]'),
        page_listing:   el.find('ol.pages'),
        empty_label:    el.find('.empty_folder')
      };

      f.pages.on('add',           this.render_page, this);
      f.pages.on('add',           this.reorder_page, this);
      f.pages.on('remove',        this.remove_page, this);
      f.pages.on('sync',          this.on_page_loaded, this);
      f.pages.on('change:title',  this.update_title, this);
      f.pages.on('change:title',  this.reorder_page, this);

      f.ctx.browser.empty_label.hide();

      f.trigger('change:parent.id', f);

      return this;
    },

    remove_folder: function(folder) {
      folder.ctx.browser.el.remove();

      if (this.ctx.current_folder == folder) {
        this.ctx.current_folder = null;
        this.ctx.current_page = null;
        this.space.trigger('reset');
      }
    },

    resource_data: function(resource) {
      return $.extend(true, resource.toJSON(), {
        path: resource.path()
      });
    },

    update_title: function(r) {
      var icon = r.ctx.browser.title.find('i').detach();
      r.ctx.browser.title.html(r.get('title')).prepend(icon);
      return true;;
    },

    reorder_folder: function(f) {

      if (f.ctx.browser && f.has_parent()) {
        var parent = f.get_parent();

        if (parent.ctx.browser) {

          var length = f.get('title').length,
              position =
                _.sortedIndex(
                  _.collect(parent.children(),
                    (function(p) { return p.get('title').toUpperCase() })),
                    f.get('title').toUpperCase()),
              listing  = parent.ctx.browser.folder_listing,
              el       = f.ctx.browser.el;

          console.log("positioning folder " + f.get('title') + ' -> ' + position + ' [' + listing.children().length + ']');

          if (position == 0) {
            listing.prepend(el);
          } else if (position >= listing.children().length) {
            listing.append(el)
          } else {
            $(listing.children()[position-1]).after(el);
          }
          if (this.ctx.current_folder != parent) {
            el.hide();
          }
        }
      }
    },

    render_page: function(page) {
      var folder  = page.folder,
          data    = this.resource_data(page),
          el      = folder.ctx.browser.page_listing.
                    append(this.templates.page(data)).children().last();

      folder.ctx.browser.empty_label.hide();

      page.ctx.browser = {
        el:     el,
        anchor: el.find('a'),
        title:  el.find('a')
      }

      if (page.isNew()) {
        page.save();
      }

      return this;
    },

    remove_page: function(page) {
      page.ctx.browser.el.remove();

      // is the last folder empty now?
      if (page.collection.folder.pages.length == 0) {
        page.collection.folder.ctx.browser.empty_label.show();
      }

      if (this.ctx.current_page == page) {
        this.ctx.current_page = null;
        this.space.trigger('reset', page);
      }
    },

    proxy_highlight_folder: function(e) {
      this.highlight_folder(this.folder_from_title($(e.target)));

      return false;
    },

    dehighlight_folder: function() {
      $("#browser .folders .selected").removeClass('selected');

      return false;
    },

    highlight_folder: function(folder) {
      if (!folder) {
        return UI.report_error("Unable to highlight folder.");
      } else if (!folder.ctx) {
        return UI.report_error("Unable to highlight folder#" + folder.get('id') + ", bad context: " + JSON.stringify(folder.ctx));
      }

      this.dehighlight_folder();

      if (!folder.ctx.browser.title.is(":visible") &&
          this.elements.go_up.attr('data-folder') == folder.get('id')) {

        this.elements.go_up.find('a').addClass('selected');

      } else {
        console.log("highlighting " + folder.get("id"))

        folder.ctx.browser.title.addClass('selected');
        this.ctx.selected_folder = folder;
        this.space.trigger('folder_selected', folder);
      }

      return this;
    },

    highlight: function(page) {
      if (!page) { page = this.ctx.current_page; }

      this.$el.find('.pages .selected').removeClass('selected');

      page.ctx.browser.el.addClass('selected');
      // return this.highlight_folder(page.folder, true);
      return this;
    },

    focus: function(page) {
      this.elements.scroller.scrollTop(page.ctx.browser.el.position().top);

      return this;
    },

    fetch_page: function(page) {
      page.fetch();
    },

    on_page_loaded: function(page) {
      this.ctx.current_page   = page;
      // this.ctx.current_folder = page.folder;

      if (page.folder != this.ctx.current_folder)
        this.switch_to_folder(page.folder);

      page.folder.collection.space.trigger('page_loaded', page);
    },

    reorder_page: function(page) {
      var page_titles = _.collect(
                          _.reject(page.collection.pluck("title"),
                            function(s) { return s == page.get('title') }),
                          function(s) { return s.toUpperCase() }),
          position =  _.sortedIndex(page_titles, page.get('title').toUpperCase()),
          listing  = page.folder.ctx.browser.page_listing,
          el       = page.ctx.browser.el;

      el.hide();

      // console.log("positioning page " + page.get('title') + ' -> ' + position + ' [' + listing.children(":visible").length + ']');

      if (position == 0) {
        listing.prepend(el);
      } else if (position == listing.children(":visible").length) {
        listing.append(el)
      } else {
        $(listing.children(":visible")[position]).before(el);
      }

      el.show();
    }
  });
});