define('views/spaces/browser/finder_navigator',
[
  'jquery',
  'backbone',
  'shortcut'
],
function( $, Backbone, Shortcut ) {

  var KC_DOWN   = 40,
      KC_UP     = 38,
      KC_ALT_UP = 1234,
      KC_LEFT   = 37,
      KC_RIGHT  = 39,
      KC_RETURN = 13,
      KC_SPACE  = 32,
      KC_ESCAPE = 27,
      KC_F2     = 113,
      KC_TAB    = 9,
      KC_DELETE = 46;

  var HIGHLIGHT   = 0,
      LOAD_FOLDER = 1,
      LOAD_PAGE   = 2;

  return Backbone.View.extend({
    el: $("#browser"),

    initialize: function(data) {
      var view = this;

      this.browser  = data.browser,
      this.ctx      = data.browser.ctx;
      this.state    = data.browser.state;

      this.events = {
        'click a': 'focus_capturer'
      };

      this.__lookup_proxy   = $.proxy(view.proxy_lookup, view);
      this.__navigate_proxy = $.proxy(view.proxy_navigate, view);
      this.__hide_capturer_on_metakey = function(e) {
        if (e.which == KC_ESCAPE || e.which == KC_RETURN) {
          view.hide_capturer();
        }

        return true;
      }

      this.elements = {
        capturer: $("#browser_input_capturer")
      }

    },

    focus_capturer: function() {
      return this.elements.capturer.focus();
    },

    unfocus_capturer: function() {
      this.state.workspace.editor.focus();

      return this;
    },

    hide_capturer: function() {
      this.elements.capturer
      .removeClass('shown')
      .val('')
      // .off('keypress', this.__lookup_proxy)
      .off('keyup', this.__hide_capturer_on_metakey);

      return this;
    },

    show_capturer: function(initial_value) {
      this.elements.capturer
      .addClass('shown')
      .val(initial_value || '')
      // .on('keypress', this.__lookup_proxy)
      .on('keyup', this.__hide_capturer_on_metakey);

      return this;
    },

    navigation: {
      next_resource: function() { return this.navigate(KC_DOWN); },
      prev_resource: function() { return this.navigate(KC_UP); },
      open_parent: function() { return this.navigate(KC_ALT_UP); },
      open_folder: function() { return this.navigate(KC_RIGHT); }
    },

    setup: function(ctx) {
      var view = this;

      Shortcut.add('ctrl+alt+down',   view.navigation.next_resource, { context: view });
      Shortcut.add('ctrl+alt+up',     view.navigation.prev_resource, { context: view });
      Shortcut.add('alt+up',          view.navigation.open_parent, { context: view });
      Shortcut.add('ctrl+alt+left',   view.navigation.open_parent, { context: view });
      Shortcut.add('ctrl+alt+right',  view.navigation.open_folder, { context: view });
      Shortcut.add('ctrl+alt+o',      view.focus_capturer, { context: view });

      this.elements.capturer
        .on('keyup', this.__navigate_proxy)
        .on('keypress', this.__lookup_proxy);

      this.delegateEvents();

      return this;
    },

    cleanup: function() {
      var view = this;

      Shortcut.remove('ctrl+alt+down',   view.navigation.next_resource);
      Shortcut.remove('ctrl+alt+up',     view.navigation.prev_resource);
      Shortcut.remove('alt+up',          view.navigation.open_parent);
      Shortcut.remove('ctrl+alt+left',   view.navigation.open_parent);
      Shortcut.remove('ctrl+alt+right',  view.navigation.open_folder);
      Shortcut.remove('ctrl+alt+o',      view.focus_capturer);

      this.undelegateEvents();

      this.elements.capturer
        .off('keyup', this.__navigate_proxy)
        .off('keypress', this.__lookup_proxy);

      this.hide_capturer();

      return this;
    },

    proxy_navigate: function(e) {
      if (e.altKey || e.ctrlKey || e.shiftKey) { return true; }

      return this.navigate(e.which, e);
    },

    navigate: function(direction, e) {
      if (this.elements.capturer.hasClass('shown')) { return true; }

      var el          = this.$el.find(".selected:visible").first(),
          el          = el.length == 1 ? el : this.$el.find(".current:visible").first(),
          set         = this.$el.find('.folder:visible > a:visible, .page:visible > a:visible'),
          idx         = set.index(el),
          setsz       = set.length,
          target      = null,
          view        = this;

      console.log('navigation current: ' + el.html() + " [" + direction + "]");
      console.log('  available choices: ' + setsz + ', me @ ' + idx);

      var locate_target = function(idx, setsz, direction, el) {
        var target_idx = null,
            action     = HIGHLIGHT;

        switch (direction) {
          case KC_DOWN: target_idx = idx == (setsz-1) ? 0 : idx + 1; break;
          case KC_UP:   target_idx = idx <= 0 ? setsz - 1 : idx - 1; break;

          case KC_F2:
            if (el.parent().hasClass('folder')) {
              view.unfocus_capturer();
              view.browser.actionbar.elements.edit_folder.click();

              return false;
            } else {
              // TODO: non-current page editing
            }
            break;
          case KC_DELETE:
            if (el.parent().hasClass('folder')) {
              view.unfocus_capturer();
              view.browser.actionbar.elements.delete_folder.click();

              return false;
            }
            else {
              // TODO: non-current page destruction
            }

            break;
          case KC_LEFT:
            if (!el.parent().hasClass('folder')) { break; }
          case KC_ALT_UP:
            if ($('#goto_parent_folder:visible').length > 0) {
              target_idx = set.index($("#goto_parent_folder > a"));
              action = LOAD_FOLDER;
            }

            break;

          case KC_RIGHT:
            // right arr only works for navigating folders
            if ($(el).parent().hasClass('folder')) {
              target_idx  = idx;
              action      = LOAD_FOLDER;
            }

            break;
          case KC_RETURN:
          case KC_SPACE:
            target_idx = idx; action = el.parent().hasClass('folder') ? LOAD_FOLDER : LOAD_PAGE;
            break;

          case KC_ESCAPE:
            if (!view.elements.capturer.is(":focus")) { return false; }

            view.browser.reset_highlights();
            view.state.workspace.editor.focus();
            break;

          case KC_TAB:
            return false;
            break;
          default:
            return false;
        }

        return { index: target_idx, action: action };
      };

      target = locate_target(idx, setsz, direction, el);

      if (!target) { return false; }

      console.log("  target idx: " + target.index);

      if (target.index >= 0) {
        target.el = set[target.index];

        if ($(target.el).hasClass('current')) {
          target    = locate_target(target.index, setsz, direction, el),
          target.el = set[target.index];

          console.log("    modified target idx: " + target.index);
        }

        console.log('action: ' + target.action);

        switch(target.action) {
          case LOAD_FOLDER:
            if ($(target.el).parent().attr('id') == 'goto_parent_folder') {
              var current_folder = this.ctx.current_folder;
              $(target.el).click().dblclick();
              this.browser.highlight_folder(current_folder);
            } else {
              $(target.el).click().dblclick();
              this.navigate(KC_DOWN);
              this.navigate(KC_DOWN);
            }

            break;

          case LOAD_PAGE:
            $(target.el).click().dblclick();
            this.browser.reset_highlights();
            break;

          default:
            $(target.el).click();
            break;
        }
      }

      return true;
    },

    proxy_lookup: function(e) {
      return this.lookup(e);
    },

    lookup: function(e) {
      if (e.which == KC_RETURN) {
        return this.hide_capturer();
      }

      if (!this.elements.capturer.hasClass('shown')) {
        this.show_capturer();
      }

      var el       = this.$el.find(".selected:visible").first(),
          el       = el.length == 1 ? el : this.$el.find(".current:visible").first(),
          set      = this.$el.find('.folder:visible > a:visible, .page:visible > a:visible'),
          captured = this.elements.capturer.val().trim().toLowerCase();

      if (captured.length == 0) {
        return true;
      }

      var target = set.filter(function() {
        return $(this).text().trim().toLowerCase().indexOf(captured) != -1;
      }).first();

      $(target).click();

      return true;
    },


  });
});