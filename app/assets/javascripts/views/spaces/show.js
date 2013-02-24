define('views/spaces/show',
[
  'backbone',
  'models/space',
  'views/spaces/resource_actions',
  'views/spaces/browser',
  'views/spaces/page_actionbar',
  'views/spaces/editor'
], function(Backbone, Space, Browser, ResourceActions, PageActionBar, Editor) {
  return Backbone.View.extend({
    initialize: function(data) {
      console.log(data)
      this.space = new Space(data.space);
      this.ctx = {
        settings_changed: false,
        settings: {
          runtime: { collapsed: [ 29 ] }
        }
      }
      
      this.resource_actions = new ResourceActions({ space: this.space, ctx: this.ctx });
      this.browser = new Browser({ space: this.space, ctx: this.ctx });
      this.editor = new Editor({ space: this.space, ctx: this.ctx });
      this.page_actionbar = new PageActionBar({ space: this.space, editor: this.editor, ctx: this.ctx });
    }
  });
})