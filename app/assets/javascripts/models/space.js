define('models/space',
  [ 'jquery', 'underscore', 'backbone', 'collections/folders' ],
  function($, _, Backbone, Folders) {
  var Space = Backbone.DeepModel.extend({
    defaults: {
      title:        "",
      pretty_title: "",
      brief:        "",
      folders:      null,
      media: {
        url:  '',
        href: ''
      }
    },

    parse: function(data) {
      return data.space;
    },

    urlRoot: function() {
      return '/users/' + this.get('creator').id + '/spaces';
    },

    initialize: function(data) {
      var self = this;

      this.folders = new Folders();
      this.folders.space = this;
      // this.folders.on('add', this.attach_to_space, this);

      _.each(data.folders, function(fdata) {
        self.folders.add(fdata);
      });
    },

    root_folder: function() {
      if (this.__root_folder) {
        return this.__root_folder;
      }

      this.__root_folder =
        _.select(this.folders.models, function(f) { return f.get('parent') == null; })[0];

      return this.__root_folder;
    },

    modify_membership: function(user_id, role, options) {
      this.save({
         memberships: [{
          user_id: user_id,
          role:    role
        }]
      }, $.extend(true, (options || {}), { patch: true, wait: true }))
    },

    is_admin: function(user) {
      var m = _.select(this.get('memberships'), function(m) { return parseInt(m.id) == parseInt(user.get('id')) })[0];
      return m && ['admin', 'creator'].indexOf(m.role) != -1;
    },

    find_page_by_fully_qualified_title: function(fqpt) {
      var folder = this.root_folder();
      var parts = fqpt.reverse();
      while (parts.length > 1) {
        var folder_title = parts.pop();

        folder = this.folders.where({ title: folder_title, 'parent.id': folder.get('id') })[0];

        if (!folder) {
          console.log("no such folder: " + folder_title);
          return null;
        }
      }

      return folder.pages.where({ title: parts[0] })[0];
    }
  });

  return Space;
});