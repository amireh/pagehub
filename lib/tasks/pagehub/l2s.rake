namespace :pagehub do
  
  # legacy to spaces structure migrations
  namespace :l2s do
    # see: l2s:perform
      
    desc "mimics the legacy schema"
    task :mimic => :environment do   
      require 'lib/tasks/pagehub/legacy_schema.exclude'
    end

    desc "renames table carbon_copies to page_carbon_copies"
    task :page_scoped_carbon_copies => :environment do
      require 'dm-migrations/migration_runner'
      migration -1, :page_scoped_carbon_copies do
        up do
          drop_table :page_carbon_copies;
          execute "RENAME TABLE carbon_copies TO page_carbon_copies;"
        end
        down do
        end
      end
      
      @@migrations.select { |m| m.name == 'page_scoped_carbon_copies' }.first.perform_up
    end
    
    desc "renames table revisions to page_revisions"
    task :page_scoped_revisions => :environment do
      require 'dm-migrations/migration_runner'
      migration -1, :page_scoped_revisions do
        up do
          drop_table :page_revisions;
          execute "RENAME TABLE revisions TO page_revisions;"
        end
        down do
        end
      end
      
      @@migrations.select { |m| m.name == 'page_scoped_revisions' }.first.perform_up
    end
    
    desc "sets an updated_at timestamp for pages that don't have it"
    task :update_page_timestamps => :environment do
      Page.all({ updated_at: nil }).update({ updated_at: DateTime.now })
    end
      
    desc "cleans up stale demo accounts"
    task :cleanup_demos => :environment do
      demo_users = User.all({ email: "demo@pagehub.org" })
      puts "Cleaning up #{demo_users.count} stale demo users"
      demo_users.destroy
    end
    
    desc "shows some hard resource numbers"
    task :stats => :mimic do
      [
        User,
        Space,
        Group,
        Page,
        Page::Revision,
        Page::CarbonCopy,
        Folder,
        PublicPage,
        SpaceUser,
        GroupUser
      ].each { |r|
        puts "#{r}: ##{r.count}"
      }
    end
    
    desc "creates an empty default space for users that dont have it"
    task :create_default_spaces => :mimic do
      nr_spaces_created = 0
      nr_spaces = Space.count
      User.all.each do |u|
        if u.owned_spaces.empty?
          u.create_default_space
          nr_spaces_created += 1
        end
      end
      
      puts "Sane delta? #{Space.count - nr_spaces == nr_spaces_created}"
      puts "Number of spaces created: #{nr_spaces_created}"
    end
    
    desc "renames user_id to creator_id for all folders and pages"
    task :attach_to_creators => :mimic do
      [Page, Folder].each do |model|
        q = { :creator_id => 0, :user_id.not => 0 }
        resources = model.all(q).collect { |r| r.id }
        puts "Updating #{resources.count} #{model.to_s.downcase}s..."
        resources.each do |r_id|
          r = model.get(r_id)
          
          unless u = User.get(r[:user_id])
            puts "WARN: User<=>Creator id mismatch for resource #{r.inspect}: no such User##{r[:user_id]}"
            puts "\tdestroying zombie resource #{model.to_s}##{r.id}"
            
            unless r.refresh.destroy
              raise "Unable to destroy zombie resource #{r.inspect}"
            end
            
            next
          end
          
          res = r.update!({ creator: u })
          unless res && r.creator && r.creator.id == r[:user_id]
            raise "Unable to attach #{model.to_s}##{r.id} to User##{r[:user_id]}: #{r.all_errors}"
          end
        end
        
        unless model.all(q).count == 0
          raise '' <<
          "Something went wrong, there should've been no more #{model.to_s}s" <<
          " left with no creator, but got #{model.all(q).count} instead"
        end
      end
      
    end
    
    desc "moves group-less folders and folder-less pages to user default spaces"
    task :populate_default_spaces => [ :create_default_spaces, :attach_to_creators ] do
      folders = Folder.all({ space_id: 0, group_id: nil }).collect { |f| f.id }
      puts "Moving #{folders.count} folders to default spaces"
      folders.each do |f_id|
        f = Folder.get(f_id)
        f.update!({ space: f.creator.default_space })
      end
      
      pages = Page.all({ :folder => nil, :group_id => nil }).map &:id
      puts "Moving #{pages.count} pages to default space root folder"
      pages.each do |pid|
        p = Page.get(pid)
        p.update!({ folder: p.creator.default_space.root_folder })
      end
    end
    
    desc "creates a space for every group"
    task :convert_groups_to_spaces => [ :create_default_spaces, :attach_to_creators ] do
      failures = []
      
      groups = Group.all.collect { |g| g.id }
      groups.each do |gid|
        g = Group.get(gid)
        
        unless u = User.get(g[:admin_id])
          puts "WARN: Admin<=>Creator id mismatch for group #{g.inspect}: no such User##{g[:admin_id]}"
          puts "\tdestroying zombie Group#{g.id}"
          
          unless g.destroy
            raise "Unable to destroy zombie group #{g.inspect}"
          end
          
          next
        end
              
        puts "\tConverting group##{g.id} -> #{g.title} [owned by: #{u.email}]"
        
        # if s = u.owned_spaces.first_or_create({ title: g.title })
        #   puts "\t\t[note]: A similar space already exists, ignoring."
        #   next
        # end
        
        s = u.owned_spaces.first_or_create({
          title:      g.title
        }, {
          is_public:  g.is_public,
          created_at: g.created_at,
          creator:    u,
          settings:   (g.settings || '').empty? ? '{}' : g.settings
        })
        
        if !s.saved?
          raise "\t\t[error]Group##{g.id} could not be migrated: #{s.all_errors}"
        end
        
        # group memberships
        memberships = g.group_users
        puts "\t\tMigrating memberships. Total: #{memberships.count}"
        memberships.each do |m|

          unless m.user
            puts "\t\t\t[warn]: User<=>User id mismatch for group membership #{m.inspect}: no such User##{m[:user_id]}"
            puts "\t\t\tdestroying zombie GroupUser#{m.inspect}"
            
            unless m.destroy
              raise "Unable to destroy zombie membership #{m.inspect}"
            end
            
            next
          end
          
          # the creator membership is automatically created on space creation
          next if m.user == s.creator
          
          begin 
            new_m = s.send("add_#{m.role.to_s}", m.user)
            puts "\t\t\t#{new_m.user.email}[#{new_m.user.provider}] is now #{new_m.role.to_s.vowelize} of #{s.title}"
          rescue Exception => e
            puts "\t\t\t[error]: Unable to migrate membership #{m.inspect} -> #{e.message.strip}"
            failures << [ e.message, m ]
          end
        end
        
        # group custom CSS has been moved to the settings field
        s.p['settings']['custom_css'] = g.css
        s.save_preferences
      end
      
      puts "Group to space conversion complete. #failures = #{failures.count}"
      if failures.any?
        puts failures.to_json
      end
    end
    
    desc "moves group folders to spaces"
    task :populate_spaces => [ :convert_groups_to_spaces ] do
      folders = Folder.all({ :space_id => 0, :group_id.not => 0 }).map(&:id)
      puts "Moving #{folders.count} folders to spaces corresponding to legacy groups."
      folders.each do |fid|
        f = Folder.get(fid)
        
        unless g = Group.get(f[:group_id])
          raise "No such group #{f[:group_id]} for folder, this shouldn't happen"
        end
        
        unless s = f.creator.spaces.first({ title: g.title })
          raise "No such corresponding space for group #{g.title} (folder: #{f.inspect})"
        end
        
        f.update!({ space: s })
      end
      
      folders = Folder.all({ folder: nil }).reject { |f| f.space.root_folder == f }.map &:id
      puts "Re-parenting #{folders.count} folders to the root folder"
      folders.each do |fid|
        f = Folder.get(fid)
        f.update!({ folder: f.space.root_folder })
      end
      
      pages = Page.all({ :group_id.not => 0, folder: nil }).map(&:id)
      puts "Moving #{pages.count} folder-less pages to space root folders"
      pages.each do |pid|
        p = Page.get(pid)
        
        unless g = Group.get(p[:group_id])
          raise "No such group #{p[:group_id]} for page, this shouldn't happen"
        end
        
        unless s = p.creator.spaces.first({ title: g.title })
          raise "No such corresponding space for group #{g.title} (page: #{p.inspect})"
        end
              
        p.update!({ folder: s.root_folder })
      end
          
    end
    
    desc "migrates data and structure from legacy version to the Space-driven one"
    task :perform => [
      :page_scoped_carbon_copies,
      :page_scoped_revisions,
      :cleanup_demos,
      :stats,
      :create_default_spaces,
      :stats,
      :attach_to_creators,
      :stats,
      :populate_default_spaces,
      :stats,
      :convert_groups_to_spaces,
      :populate_spaces
    ] do
      puts "Migration complete."
      puts "Verifying datastore integrity..."
      
      nr_spaces = Space.count
      unless nr_spaces == Group.count + User.count
        raise "Unexpected number of spaces #{Space.count}, should've been #{Group.count + User.count}"
      end
      
      if User.all({ email: "demo@pagehub.org" }).any?
        raise "Expected all demo users to be removed, but there's still some."
      end
      
      User.all.each do |u|
        if !u.default_space
          raise "Expected all users to have a default space, but User##{u.id} doesn't"
        end
      end
      
      Space.all.each do |s|
        if !s.root_folder
          raise "Expected all spaces to have a root folder, but Space##{s.id} doesn't"
        end
      end
      
      [ Folder, Page ].each do |model|
        creatorless_resources = model.all({ creator: nil })
        if creatorless_resources.any?
          raise '' <<
          "Expected all #{model} objects to be assigned a :creator, " <<
          "but #{creatorless_resources.count} don't" <<
          "\n\nResources: #{creatorless_resources.map(&:id)}"
        end
      end
      
      spaceless_folders = Folder.all({ space: nil })
      if spaceless_folders.any?
        raise "Expected all folders to be assigned to a space" <<
        " but #{spaceless_folders.count} aren't. " <<
        "\n\nFolders: #{spaceless_folders.collect(&:id)}"
      end

      orphaned_folders = Folder.all({ folder: nil })
      unless orphaned_folders.count == nr_spaces
        raise "Unexpected number of orphaned folders;" <<
        " should've been 1:1 with space count (#{nr_spaces}), but" <<
        " got #{orphaned_folders.count} instead. " <<
        "\n\nFolders: #{orphaned_folders.collect(&:id)}"
      end
     
      folderless_pages = Page.all({ folder: nil })
      if folderless_pages.any?
        raise "Expected all pages to be attached to a folder, " <<
        "but #{folderless_pages.count} pages aren't." <<
        "\n\nPages: #{folderless_pages.collect(&:id)}" 
        puts "Ok, looks good."
      end
      
      # ---
      # clean up the schema, remove unused tables and columns
      puts "Cleaning up database schema (removing unused tables, columns, etc.)"
      
      require 'dm-migrations/migration_runner'
      migration -1, :from_legacy_to_spaces do
        up do
          drop_table :groups
          drop_table :group_users
          drop_table :group_pages
          drop_table :tags
          drop_table :page_tags
          
          [ :pages, :folders ].each do |tname|
            modify_table tname do
              drop_column :group_id
              drop_column :user_id
            end
          end
        end

        down do
        end
      end
      
      @@migrations.select { |m| m.name == 'from_legacy_to_spaces' }.first.perform_up
    end
    
  end # l2s
end # pagehub