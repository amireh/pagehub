define('views/spaces/browser/browser',
[
  'jquery',
  'backbone',
  'views/spaces/browser/drag_manager',
  'views/spaces/browser/actionbar',
  'views/spaces/browser/settings',
  'views/spaces/browser/_impl',
  'views/spaces/browser/finder',
  'views/spaces/browser/explorer',
  'hb!browser/folder.hbs',
  'hb!browser/page.hbs',
  'hb!dialogs/destroy_folder.hbs',
  'pagehub',
  'shortcut',
  'jquery.tinysort'
],
function( $, Backbone, DragManager, ActionBar, Settings, BrowserImplementation, Finder, Explorer, FolderTemplate, PageTemplate, DestroyFolderTmpl, UI, Shortcut ) {

  return Backbone.View.extend({
    el: $("#browser"),

    templates: {
      folder: FolderTemplate,
      page:   PageTemplate
    },

    events: {
      'click .folder > a:not(.selected, .current)': 'proxy_highlight_folder',
      'click .page   > a:not(.selected, .current)': 'proxy_highlight_page',
      'click .current': 'reset_highlights',

    },

    initialize: function(data) {
      var view = this;

      _.implode(this, data);

      this.offset = 145;

      // workspace events
      this.workspace.on('folder_loaded',  this.switch_to_folder, this);
      this.workspace.on('page_loaded',    this.switch_to_folder_and_load_page, this);
      // this.space.on('page_loaded',  this.proxy_highlight_page, this);

      // -- disabled --
      // focus/scrolling behaviour is really inconsistent across browsers
      // disabling for now
      //
      // this.space.on('page_loaded',  this.focus,     this);
      $(window).on('resize', function() { return view.resize(); });

      // TODO:  make this trigger a route so that there's a single entry point
      //        into loading pages
      // this.space.on('page_created', this.switch_to_folder_and_load_page, this);
      this.workspace.on('reset', this.reset_highlights, this);
      this.workspace.on('reset', this.reset_current_highlights, this);

      // folder events
      this.space.folders.on('add',          this.render_folder, this);
      this.space.folders.on('remove',       this.remove_folder, this);
      this.space.folders.on('change:title', this.update_meta, this);
      this.space.folders.on('change:path', this.update_meta, this);
      this.space.folders.on('change:title', this.reorder_folder, this);
      this.space.folders.on('change:parent.id', this.refresh_folder_pages, this);
      this.space.folders.on('change:parent.id', this.reorder_folder, this);

      this.state.current_user.on('change:preferences.workspace.browser.type', this.render, this);
      this.state.current_user.on('change:preferences.workspace.scrolling', this.resize, this);

      // this.drag_manager = new DragManager(data);
      this.actionbar = new ActionBar({ browser: this });
      this.settings  = new Settings({  browser: this });

      this.elements = {
        scroller: $("#browser_scroller")
      }

      // this.impl = new BrowserImplementation();
      this.__finder   = new Finder({ state: this.state, workspace: this.workspace, browser: this });
      this.__explorer = new Explorer({ state: this.state, workspace: this.workspace });

      Shortcut.add('ctrl+alt+g', function() {
        view.set_browser_type(view.impl.browser_type == 'explorer' ? 'finder' : 'explorer');
      });

      this.render();

      this.state.on('bootstrapped', function() {
        this.$el.show();

        // sort the folder listing
        //
        // the reason we need to manually do this on bootstrap is because
        // the folders are flattened in the space contrary to the page collections
        // where they are scoped per folder and would be rendered only when their folder
        // is rendered
        this.space.folders.every(function(f) {
          f.pages.on('add', this.reorder_page, this);

          this.reorder_folder(f);

          return true;
        }, this);

        if (this.workspace.current_folder) {
          this.impl.on_folder_loaded(this.workspace.current_folder);
          this.focus();
        }

        this.space.folders.on('add', this.reorder_folder, this);
      }, this);
    },

    set_browser_type: function(type) {
      if (this.impl && this.impl.browser_type == type) {
        return this;
      }

      if (this.impl) {
        this.impl.reset(this.ctx);
      }

      this.impl = type == 'explorer' ? this.__explorer : this.__finder;
      this.impl.render(this.ctx);

      return this;
    },

    render: function() {
      this.resize();
      this.set_browser_type(this.state.current_user.get('preferences.workspace.browser.type') || 'finder');

      this.focus();

      return this;
    },

    focus: function() {
      if (this.workspace.current_page) {
        this.workspace.current_page.ctx.browser.title.focus();
      }
      else if (this.workspace.current_folder) {
        this.workspace.current_folder.ctx.browser.title.focus();
      }

      return this;
    },

    pass: function(e) {
      return true;
    },

    consume: function(e) {
      e.preventDefault();
      return false;
    },

    resize: function() {
      if (this.state.current_user.get('preferences.workspace.scrolling')) {
        this.elements.scroller.css({
          "max-height": $(window).height() - this.offset,
          "min-height": "inherit"
        });
      } else {
        this.elements.scroller.css({
          "max-height": "inherit",
          "min-height": $(window).height() - this.offset
        });
      }
    },

    // -- utility -- //
    folder_from_title: function(el) {
      var folder_el = $(el).parents(".folder:first"),
          id        = null;

      if (folder_el.attr('data-folder')) {
        id = folder_el.attr('data-folder');
      } else if (folder_el.attr('id')) {
        id = folder_el.attr("id").replace('folder_', '');
      }
      return this.space.folders.get( id );
    },

    // -- utility -- //
    page_from_title: function(el) {
      var el = $(el).parents(".page:first"),
          folder_id = null,
          page_id   = null;

      var folder = this.space.folders.get(el.attr('data-folder'));
      if (folder) {
        return folder.pages.get(el.attr('data-page'));
      }

      return null;
    },

    resource_data: function(resource) {
      return $.extend(true, resource.toJSON(), {
        path: resource.path()
      });
    },

    render_folder: function(f) {
      var data    = this.resource_data(f),
          entry   = this.templates.folder(data),
          target  = this.$el,
          el      = target.append( entry ).children().last();

      f.ctx.browser = {
        el:               el,
        title:            el.find('> .folder-title'),
        anchor:           el.find('> .folder-title'),
        title_icon:       el.find('> .folder-title i'),
        collapser:        el.find('button[data-collapse]'),
        folder_listing:   el.find('ol.folders'),
        page_listing:     el.find('ol.pages'),
        empty_label:      el.find('.empty-folder')
      };

      f.pages.on('add',           this.render_page, this);
      f.pages.on('remove',        this.remove_page, this);
      f.pages.on('change:title',  this.update_meta, this);
      f.pages.on('change:path',   this.update_meta, this);
      f.pages.on('change:title',   this.reorder_page, this);

      this.impl.on_folder_rendered(f);
      // this.reorder_folder(f);

      f.ctx.browser.empty_label.show();

      return this;
    },

    remove_folder: function(folder) {
      folder.ctx.browser.el.remove();
    },

    render_page: function(page) {
      var data    = this.resource_data(page),
          folder  = page.collection.folder,
          el      = folder.ctx.browser.page_listing.
                    append(this.templates.page(data)).children().last();

      folder.ctx.browser.empty_label.hide();

      page.ctx.browser = {
        el:         el,
        anchor:     el.find('a'),
        title:      el.find('a'),
        title_icon: el.find('i')
      }

      this.impl.on_page_rendered(page);

      return this;
    },

    remove_page: function(page) {
      page.ctx.browser.el.remove();

      // is the last folder empty now?
      page.folder.ctx.browser.empty_label.toggle(page.folder.pages.length == 0);

      // TODO: the conditional is redundant since only the current
      // page can be destroyed anyway
      // if (this.workspace.current_page == page) {
      //   this.workspace.trigger('reset');
      //   this.workspace.current_folder = page.collection.folder;
      // }
    },

    // reset selections
    reset_highlights: function() {
      this.impl.dehighlight_folder(this.ctx.selected_folder);
      this.impl.dehighlight_page(this.ctx.selected_page);

      this.ctx.selected_folder  = null;
      this.ctx.selected_page    = null;

      return this;
    },

    // reset current resource selections
    reset_current_highlights: function() {
      // console.log('[browser] -- resetting current highlights -- ');

      this.impl.dehighlight_current_folder();
      this.impl.dehighlight_current_page();

      return this;
    },

    proxy_highlight_folder: function(e) {
      this.highlight_folder(this.folder_from_title($(e.target)));

      return this.consume(e);
    },

    highlight_folder: function(folder) {
      if (!folder) {
        return UI.report_error("[browser]: no such folder to highlight");
      }

      this.reset_highlights();

      this.ctx.selected_folder = folder;
      this.impl.highlight_folder(folder);

      this.trigger('folder_selected', folder);
    },

    proxy_highlight_page: function(e) {
      this.highlight_page(this.page_from_title($(e.target)));

      return this.consume(e);
    },

    highlight_page: function(page) {
      if (!page) {
        return UI.report_error("[browser]: no such page to highlight");
      }

      this.reset_highlights();

      this.ctx.selected_page = page;
      this.impl.highlight_page(page);

      this.trigger('page_selected', page);
    },

    switch_to_folder: function(f) {
      this.impl.on_folder_loaded(f);
      this.impl.highlight_current_folder(f);

      return this;
    },

    switch_to_folder_and_load_page: function(page) {
      this.reset_current_highlights();

      this.impl.highlight_current_page(page);

      return this;
    },

    update_meta: function(r) {
      if (!r.ctx.browser) { return null; }

      console.log("updating resource meta: " + r.get('title'));

      var icon = r.ctx.browser.title_icon.detach();

      r.ctx.browser.title.html(r.get('title')).prepend(icon);
      r.ctx.browser.anchor.attr('href', '#' + r.path());

      return true;
    },

    reorder_folder: function(f) {
      var parent = f.get_parent();

      if (f.ctx.browser && parent && parent.ctx.browser) {
        var listing = parent.ctx.browser.folder_listing,
            el      = f.ctx.browser.el;

        listing.append(el);
        listing.find('> li:not([data-meta])').tsort('> .folder-title');

        // this.trigger('folder_reordered', f, parent);
      }
    },

    reorder_page: function(page) {
      if (!page.ctx.browser) { return null; }

      var listing = page.collection.folder.ctx.browser.page_listing,
          el      = page.ctx.browser.el;

      console.log("repositioning page within " + page.collection.folder.get("title"))

      listing.append(el);
      listing.find('li').tsort('> a:first-child');
    },

  });
});