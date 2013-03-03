define('views/spaces/show',
[
  'backbone',
  'models/space',
  'views/spaces/resource_actions',
  'views/spaces/browser',
  'views/spaces/page_actionbar',
  'views/spaces/editor',
  'pagehub'
], function(Backbone, Space, Browser, ResourceActions, PageActionBar, Editor, UI) {
  return Backbone.View.extend({
    initialize: function(state) {
      UI.status.mark_pending();

      this.space = state.space;
      this.ctx = {
        settings_changed: false,
        settings: {
          runtime: { collapsed: [ ] }
        }
      }

      this.resource_actions = new ResourceActions({ space: this.space, ctx: this.ctx });
      this.browser = new Browser({ space: this.space, ctx: this.ctx });
      this.editor = new Editor({ space: this.space, ctx: this.ctx });
      this.page_actionbar = new PageActionBar({ space: this.space, editor: this.editor, ctx: this.ctx });

      UI.status.mark_ready();
    }
  });
})