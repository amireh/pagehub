define('views/spaces/browser',
[ 
  'jquery',
  'backbone',
  'hb!browser/folder.hbs',
  'hb!browser/page.hbs',
  'hb!dialogs/destroy_folder.hbs',
  'pagehub'
],
function( $, Backbone, FolderTemplate, PageTemplate, DestroyFolderTmpl, UI ) {
  return Backbone.View.extend({
    el: $("#browser"),
    templates: {
      folder: FolderTemplate,
      page:   PageTemplate
    },
    
    events: {
      'click li a': 'load_page',
      'click .edit_folder': 'edit_folder',
      'click .delete_folder': 'delete_folder',
      'click button[data-collapse]': 'collapse',
      'click .folder_title': 'collapse'
    },
    
    initialize: function(data) {
      this.space  = data.space,
      this.ctx    = data.ctx;

      this.space.on('load_page',    this.on_load_page, this);
      this.space.on('page_loaded',  this.highlight, this);
      this.space.on('page_created', this.on_page_loaded, this);
      this.space.on('reset', this.reset, this);
      this.space.folders.on('add', this.render_folder, this);
      this.space.folders.on('destroy', this.remove_folder, this);
      this.space.folders.on('change:title', this.update_title, this);
      this.space.folders.on('change:parent.id', this.update_folder_position, this);
      
      this.bootstrap();
    },
    
    bootstrap: function() {
      this.resize();
      
      console.log("Rendering " + this.space.folders.models.length + " folders");
      
      this.space.folders.every(function(f) {
        return this.space.folders.trigger('add', f);
      }, this);
      
      return this;
    },
    
    reset: function() {
      this.$el.find('.selected').removeClass('selected');
    },
    
    resize: function() {
      $("#pages .scroller").css("max-height", $(window).height() - 135);
    },    
    
    render_folder: function(f) {
      console.log(f);
      var entry = this.templates.folder(f.toJSON());
          // target = f.has_parent() ? f.get_parent().ctx.browser.folder_listing : this.$el,
          // target = this.$el,
      
      var target = this.$el;
      
      if (f.has_parent()) {
        try { target = f.get_parent().ctx.browser.folder_listing }
        catch (e) { target = this.$el; console.log("Unable to attach folder to parent: " + e) }
      }
      
      var el = target.append( entry ).children().last();
      
      f.ctx.browser = {
        el:           el,
        title:          el.find('span.folder_title'),
        folder_listing: el.find('ol.folders'),
        page_listing:   el.find('ol.pages'),
        empty_label:    el.find('.empty_folder')
      };
      
      if (!f.has_parent()) {
        f.ctx.browser.el.addClass('general-folder');
      }
      
      // f.bind('change:parent.id', function(f) {
      //   console.log("repositioned")
      // });
      
      f.pages.on('add',     this.render_page, this);
      f.pages.on('destroy', this.remove_page, this);
      f.pages.on('change:title', this.update_title, this);
      f.pages.every(function(p) {
        return this.pages.trigger('add', p);
      }, f);
      
      this.space.folders.every(function(folder) {
        if (folder.has_parent() && folder.get_parent() == f && folder.ctx.browser) {
          f.ctx.browser.folder_listing.append( folder.ctx.browser.el );
        }
        return true;
      }, this);
      
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

    update_title: function(r) {
      r.ctx.browser.title.html(r.get('title'))
    },
    
    update_folder_position: function(f) {
      if (f.ctx.browser && f.has_parent()) {
        var parent = f.get_parent();
        if (parent.ctx.browser) {
          parent.ctx.browser.folder_listing.append(f.ctx.browser.el)
        }
      }
    },
    
    render_page: function(page) {
      var folder  = page.folder,
          el      = folder.ctx.browser.page_listing.
                    append(this.templates.page(page.toJSON())).children().last();
      
      folder.ctx.browser.empty_label.hide();
      
      page.on('sync', this.on_page_loaded, this);
      page.on('change:folder_id', this.on_page_moved, this);
      
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
      if (page.folder.pages.length == 0) {
        page.folder.ctx.browser.empty_label.show();
      }
      
      if (this.ctx.current_page == page) {
        this.ctx.current_page = null;
        this.space.trigger('reset');
      }
    },

    highlight: function(page) {
      if (!page) { page = this.ctx.current_page; }
      this.reset();
      page.ctx.browser.el.addClass('selected');
      page.folder.ctx.browser.title.addClass('selected');
      // page.ctx.browser.el.append( $("#indicator").show() );
    },
    
    load_page: function(e) {
      var a         = $(e.toElement),
          page_id   = parseInt(a.attr("id").replace('page_', '')),
          folder_id = parseInt(a.parents(".folder:first").attr("id").replace('folder_', '')),
          folder    = this.space.folders.get(folder_id),
          page      = folder.pages.get(page_id);

      e.preventDefault();
      
      this.space.trigger('load_page', page);
      
      return false;
    },
    
    on_load_page: function(page) {
      try {
        if (page.isNew()) {
          page.save();
        } else {
          page.fetch();          
        }
      } catch(err) {
        UI.status.show(err, "bad");
        // console.log(err)
      }
    },
    
    on_page_loaded: function(page) {
      this.ctx.current_page   = page;
      this.ctx.current_folder = page.folder;
      page.folder.collection.space.trigger('page_loaded', page);
    },
    
    on_page_moved: function(page) {
      page.folder.ctx.browser.page_listing.append(page.ctx.browser.el)
    },
    
    edit_folder: function(evt) {
      var el      = $(evt.toElement),
          folder  = this.space.folders.get( parseInt( el.parent().attr("id").replace('folder_', ''))),
          space   = this.space;
      
      $.ajax({
        type:   "GET",
        accept: "text/html",
        url:    folder.get('media').url + '/edit',
        success: function(dialog_html) {
          var dialog = $("<div>" + dialog_html + "</div>").dialog({
            title: "Editing a folder"
          });
          
          dialog.find('form').on('submit', function(e) {
            var folder_data = $(this).serializeObject();
            folder.save(folder_data, {
              wait: true,
              patch: true
            });
            
            dialog.dialog("close");
            e.preventDefault();
          });
          
          dialog.find('button.cancel').on('click', function(e) {
            e.preventDefault();
            dialog.dialog("close");
          });
        }
      });
    }, // edit_folder
    
    delete_folder: function(evt) {
      var view    = this,
          folder  = this.space.folders.get(parseInt($(evt.toElement).parent().attr("id").replace('folder_', ''))),
          data    = folder.toJSON();
      
      data.nr_pages     = folder.pages.length;
      data.nr_folders   = folder.children().length;
      
      var el      = DestroyFolderTmpl(data);

      $(el).dialog({
        title: "Folder removal",
        buttons: {
          Cancel: function() {
            $(this).dialog("close");
          },
          Remove: function() {
            folder.destroy();
            $(this).dialog("close");
          }
        }
      });
    },
    
    collapse: function(evt) {
      var source = $(evt.toElement);
      
      if (source.attr("data-collapse") == null)
        source = source.siblings("[data-collapse]:first");

      var folder_id = parseInt(source.attr("data-folder"));
      
      if (source.attr("data-collapsed")) {
        source.siblings(":not(span.folder_title)").show();
        source.attr("data-collapsed", null).html("&minus;");
        source.parent().removeClass("collapsed");

        this.ctx.settings.runtime.collapsed.pop_value(folder_id);
        this.ctx.settings_changed = true;
      } else {
        source.siblings(":not(span.folder_title)").hide();
        source.attr("data-collapsed", true).html("&plus;");
        source.parent().addClass("collapsed");

        this.ctx.settings.runtime.collapsed.push(folder_id);
        this.ctx.settings_changed = true;
      }
    }
  })
})