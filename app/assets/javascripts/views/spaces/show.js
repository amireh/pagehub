define('views/spaces/show',
[
  'models/space',
  'views/spaces/resource_actions',
  'views/spaces/browser',
  'views/spaces/page_actionbar',
  'views/spaces/editor'
], function(Space, Browser, ResourceActions, PageActionBar, Editor) {
  return Backbone.View.extend({
    initialize: function(data) {
      this.ctx = {}
      this.space = new Space(data.space);
      this.resource_actions = new ResourceActions({ space: this.space, ctx: this.ctx });
      this.browser = new Browser({ space: this.space, ctx: this.ctx });
      this.editor = new Editor({ space: this.space, ctx: this.ctx });
      this.page_actionbar = new PageActionBar({ space: this.space, editor: this.editor, ctx: this.ctx });
    }
  });
})