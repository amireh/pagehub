define('views/spaces/browser/explorer',
[
  'jquery',
  'backbone',
  'views/spaces/browser/_impl',
  'views/spaces/browser/drag_manager',
  'pagehub'
],
function( $, Backbone, BrowserImplementation, DragManager, UI ) {

  var
  init_collapsed_setting = function(object) {
    if (!get_collapsed_setting(object)) {
      object.state.current_user.set('preferences.runtime.spaces.' + object.state.space.get('id'), { collapsed: [] });
    }

    return true;
  },
  get_collapsed_setting = function(object) {
    return object.state.current_user.get('preferences.runtime.spaces.' + object.state.space.get('id') + '.collapsed');
  },
  set_collapsed_setting = function(object, value) {
    return object.state.current_user.set('preferences.runtime.spaces.' + object.state.space.get('id') + '.collapsed', value);
  }

  return BrowserImplementation.extend({
    events: {
      // 'click button[data-collapse]':  'proxy_collapse',
      // 'dblclick .folder_title':       'proxy_collapse',
      'mouseenter .folder_title': 'highlight_hierarchy',
      'mouseleave .folder_title': 'dehighlight_hierarchy'
    },

    initialize: function(data) {
      // this.drag_manager = new DragManager(data);
      this.state = data.state;

      this.css_class = 'explorer-like';
      this.browser_type = 'explorer';

      init_collapsed_setting(this);
    },

    on_folder_loaded: function(f) { return this.highlight_folder(f); },

    setup: function(ctx) {
      if (ctx.current_page) {
        this.highlight_page(ctx.current_page)
      }

      if (ctx.current_folder) {
        this.highlight_folder(ctx.current_folder)
      }

      $(".pages").each(function(listing) {
        if ($(listing).children(":visible").length == 0) {
          $(listing).find('.empty_folder').show();
        }
      });
    },

    cleanup: function() {
      this.$el.find('.highlighted').removeClass(".highlighted");
    },

    on_folder_rendered: function(f) {
      // if (this.ctx.settings.runtime.collapsed.indexOf(parseInt( f.get('id') )) != -1) {
      if (get_collapsed_setting(this).indexOf(parseInt( f.get('id') )) != -1) {
        // this.__collapse(f.ctx.browser.collapser);
      }

      return this;
    },

    highlight_folder: function(folder) {
      console.log("highlighting folder " +folder.get('title'))
      folder.ctx.browser
        .title
        .add(folder.ctx.browser.el.parents('.folder').find('> span.folder_title a'))
        .addClass('selected');

      return this;
    },

    dehighlight_folder: function() {
      this.$el.find(".folders .selected").removeClass('selected');

      return this;
    },

    highlight_page: function(page) {
      page.ctx.browser.el.addClass('selected');

      return this.highlight_folder(page.folder);
    },

    // collapse: function(evt) {
    //   // var source = $(evt.target);
    //   var source = $(evt.target);

    //   if (source.attr("data-collapse") == null) {
    //     source = source.parents(".folder:first").find('[data-collapse]:first');
    //   }

    //   this.__collapse(source);
    //   var data = { preferences: { runtime: { spaces: {} } } };

    //   data.preferences.runtime.spaces[this.state.space.get('id')] = {
    //     collapsed: get_collapsed_setting(this)
    //   };

    //   this.state.trigger('sync_runtime_preferences', data);
    // },

    // __expand: function(folder) {

    // },

    // __collapse: function(folder) {

    // }
    // collapse: function(source) {
    //   var folder_id = parseInt(source.parent().attr("id").replace('folder_', '')),
    //       collapsed = source.attr("data-collapsed");

    //   if (collapsed) {
    //     // source.parent().siblings().show();
    //     source.siblings(":not(span.folder_title)").show();
    //     var caption = source.attr("data-collapsed-caption");
    //     source.attr("data-collapsed-caption", source.html());
    //     source.attr("data-collapsed", null).html(caption);
    //     source.parent().removeClass("collapsed");

    //     set_collapsed_setting(this, get_collapsed_setting(this).pop_value(folder_id));
    //   } else {
    //     source.siblings(":not(span.folder_title)").hide();
    //     // source.parent().siblings().hide();
    //     var caption = source.attr("data-collapsed-caption");
    //     source.attr("data-collapsed-caption", source.html());
    //     source.attr("data-collapsed", true).html(caption);
    //     source.parent().addClass("collapsed");

    //     get_collapsed_setting(this).push(folder_id);
    //     // this.ctx.settings.runtime.collapsed.push(folder_id);
    //     // this.ctx.settings_changed = true;
    //   }
    // },

    highlight_hierarchy: function(evt) {
      $(evt.target).
        addClass("highlighted").
        parents(".folder").find("> span.folder_title a").addClass("highlighted");
    },

    dehighlight_hierarchy: function(evt) {
      this.$el.find('.highlighted').removeClass("highlighted");
    }

  });
});