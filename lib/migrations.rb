# Forcing some sane limits on fields
migration 1, :change_string_lengths do
  up do
    adapter = DataMapper.repository(:default).adapter
    # puts adapter.inspect
    namesz = 120
    { "users" => {
        "email" => 255,
        "name" => namesz,
        "nickname" => namesz,
        "password" => 64,
        "provider" => 255,
        "uid" => 255
      },
      "groups" => { "name" => namesz, "title" => namesz },
      "pages" => { "title" => 255, "pretty_title" => 255 }
    }.each_pair { |table, entries|
      entries.each_pair { |col, sz|
        query = "ALTER TABLE #{table} MODIFY COLUMN #{col} varchar(#{sz});"
        adapter.execute(query)
      }
    }
  end

  down do
  end
end

# Folder and Page models are no longer separate entities
# but instead inherit from the Resource model, so DataMapper
# by default uses a joined table (called `resources`) to hold
# both types of records (identified by the unique `type` field).
#
# What this migration has to do is fool DM into using the old
# recordset (tables `folders` and `pages`), get the old records
# and convert them into Resources (by adding the required `type`).
migration 2, :convert_to_resources do
  up do
    adapter = DataMapper.repository(:default).adapter

    # migrate pages
    begin; adapter.execute("ALTER TABLE pages DROP type;"); rescue; end
    # and folders
    begin; adapter.execute("ALTER TABLE folders DROP type;"); rescue; end

    adapter.execute("ALTER TABLE pages ADD COLUMN type VARCHAR(50);")
    adapter.execute("ALTER TABLE folders ADD COLUMN type VARCHAR(50);")
    adapter.execute("UPDATE pages set type='Page';")
    adapter.execute("UPDATE folders set type='Folder';")

    class Folder; storage_names[:default] = "folders"; end
    class Page; storage_names[:default] = "pages"; end

    # recreate all the folders...
    old_folders = []
    Folder.all.each { |f|
      old_folders << { 
        id:           f.id,
        title:        f.title,
        pretty_title: f.pretty_title,
        user_id:      f.user_id,
        folder_id:    f.folder_id,
        created_at:   f.created_at
      }
      of = old_folders.last
      puts "\tOld folder: #{of[:id]} #{of[:title]} #{of[:pretty_title]} => #{of[:user_id]} #{of[:folder]}"
    }
    puts "Migrating #{old_folders.size} old folders"
    class Folder; storage_names[:default] = "resources"; end
    old_folders.each { |of|
      if !Folder.create(of)
        puts "ERROR: unable to create folder #{of}"
        break
      end
    }
    # folders need to be re-linked after creation,
    # because looking them up in the loop above will
    # not work as they would not have been created yet
    puts "Linking folders"
    old_folders.each { |of|
      if of[:folder_id] then
        Folder.get(of[:id]).update(folder_id: of[:folder_id])
      end
    }

    old_pages = []
    Page.all.each { |p|
      old_pages << { 
        id: p.id,
        title: p.title,
        pretty_title: p.pretty_title,
        content: p.content,
        user: p.user,
        folder: p.folder,
        created_at: p.created_at,
        type: "Page"
      }
      op = old_pages.last
      puts "\tOld page: #{op[:id]} #{op[:title]} #{op[:pretty_title]} => \
            user: #{op[:user_id]} folder: #{op[:folder_id]}, #{op[:content] ? op[:content].size : ''}"
    }
    puts "Migrating #{old_pages.size} old pages"
    class Page; storage_names[:default] = "resources"; end
    old_pages.each { |op|
      if !Page.create(op)
        puts "ERROR: unable to create page #{op}"
        break
      end
    }

  end
  down do
    adapter = DataMapper.repository(:default).adapter
    begin adapter.execute("ALTER TABLE pages DROP type;"); rescue; end
    begin adapter.execute("ALTER TABLE folders DROP type;"); rescue; end
    begin adapter.execute("TRUNCATE resources;"); rescue; end
  end
end

migration 3, :default_folders do
  up do
    User.all.each { |u|
      f = Folder.new({ title: "None", user: u, is_default: true })
      f.folder = f
      f.save

      if !f.valid?
        puts "ERROR: Default folder could not be created:"
        puts eidx = 1
        f.errors.each { |e|
          puts "\t#{eidx} => #{e}"
          eidx += 1
        }

        raise RuntimeError.new("Default folder creation failed")
      end

      puts "Default folder: #{f.inspect}"

      # link folderless pages to the default one
      puts "#{u.pages.count({ folder: nil })} orphaned pages"
      u.pages.all({ folder: nil }).each { |p|
        p.update({ folder: f })
      }
      puts "#{u.pages.count({ folder: nil })} orphaned pages remain."

      # link folders to the default one
      puts "#{u.folders.count({ folder: nil })} orphaned folders"
      u.folders.all({ folder: nil }).each { |orphan_f|
        orphan_f.update({ folder: f })
      }
      puts "#{u.folders.count({ folder: nil })} orphaned folders remain."


    }
  end

  down do
    User.all.each { |u|
      f = u.default_folder
      if f
        u.folders.all({ folder_id: f.id }).each { |child_f| child_f.update!(folder: nil) }
        f.destroy
      end
   }
  end
end