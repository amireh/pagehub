define('views/spaces/browser',
[ 
  'jquery',
  'backbone',
  'hb!browser/folder.hbs',
  'hb!browser/page.hbs'
],
function( $, Backbone, FolderTemplate, PageTemplate ) {
  return Backbone.View.extend({
    el: $("#browser"),
    templates: {
      folder: FolderTemplate,
      page:   PageTemplate
    },
    
    events: {
      'click a': 'load_page'
    },
    
    initialize: function(data) {
      this.space  = data.space,
      this.ctx    = data.ctx;

      this.space.on('load_page',    this.on_load_page, this);
      this.space.on('page_loaded',  this.highlight, this);
      this.space.on('page_created', this.on_page_loaded, this);
      this.space.folders.on('add', this.render_folder, this);
      this.space.folders.on('change:title', this.update_folder_title, this);
      
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
    
    resize: function() {
      $("#pages .scroller").css("max-height", $(window).height() - 135);
    },    
    
    render_folder: function(f) {
      var el = this.$el.append( this.templates.folder(f.toJSON()) ).children().last();
      
      f.ctx.browser = {
        el:           el,
        title:        el.find('span.folder_title'),
        page_listing: el.find('ol.pages')
      };
      
      f.pages.on('add', this.render_page, this);
      f.pages.every(function(p) {
        return this.pages.trigger('add', p);
      }, f);
      
      
      return this;
    },
    
    update_folder_title: function(f) {
    },
    
    render_page: function(page) {
      var folder  = page.folder,
          el      = folder.ctx.browser.page_listing.
                    append(this.templates.page(page.toJSON())).children().last();
      
      page.on('sync', this.on_page_loaded, this);
      
      page.ctx.browser = {
        el:     el,
        anchor: el.find('a')
      }
      
      if (page.isNew()) {
        page.save();
      }
      
      return this;
    },
        
    highlight: function(page) {
      if (!page) { page = this.ctx.current_page; }
      this.$el.find('.selected').removeClass('selected');
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
        ui.status.show(err, "bad");
        // console.log(err)
      }
    },
    
    on_page_loaded: function(page) {
      console.log("page loaded: " + page.get('id') + ' -> ' + page.get('title'))
      console.log(page);
      this.ctx.current_page   = page;
      this.ctx.current_folder = page.folder;
      page.folder.space.trigger('page_loaded', page);
    }
  })
})