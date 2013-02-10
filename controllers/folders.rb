# Create an empty folder, must be unique by title in the user's scope
def create_folder(gid = nil)
  # locate parent folder, if any
  parent = nil
  if params[:folder_id] && params[:folder_id].to_i != 0 then
    parent = @scope.folders.first({ id: params[:folder_id] })

    halt 400, "No such parent folder with the id #{parent_id}" if !parent
  end

  f = @scope.folders.create({
    title: params[:title],
    user: current_user,
    folder: parent
  })

  # see models/datamapper_resource.rb for DataMapper::Resource.persisted?
  unless f.saved?
    halt 400, f.collect_errors
  end

  f.to_json
end

# Updates the folder's title and its parent containing folder
def update_folder(fid, gid = nil)
  unless f = @scope.folders.first({ id: fid })
    halt 400, "That folder does not exist."
  end

  # should the title be updated?
  unless params[:title].nil? || params[:title].empty?
    f.title = params[:title]
  end

  parent_id = params[:folder_id].to_i
  if parent_id == 0 then
    f.folder = nil # has detached the folder from its parent
  else
    unless parent = @scope.folders.first(id: parent_id)
      halt 500, "No such parent folder with the id #{parent_id}"
    end

    f.folder = parent
  end

  unless f.save
    halt 500, f.collect_errors
  end

  f.to_json
end

# Add a page to this folder
def add_to_folder(fid, pid, gid = nil)
  unless p = @scope.pages.first(id: pid)
    halt 400, "That page does not exist."
  end

  # Folder#0 is special - it's the no-folder folder!
  if fid.to_i == 0 then
    unless p.update(folder: nil)
      halt 500, "Unable to update that page."
    end

    return p.to_json
  end

  unless f = @scope.folders.first(id: fid)
    halt 400, "That folder does not exist."
  end

  f.pages << p

  unless f.save
    halt 500, f.collect_errors
  end

  p.to_json
end

def __dump_folder(f, out)
  out << f.serialize

  f.folders.each { |of| __dump_folder(of, out)
    # orphans[:folders] << of.serialize.delete!(:parent)
  }
end

def delete_folder(fid, gid = nil)
  unless f = @scope.folders.first({ id: fid })
    halt 400, "That folder does not exist."
  end

  f.operating_user = current_user
  parent = f.folder
  orphans = {}
  if !parent then
    orphans = { folders: [] }

    f.folders.each { |of|
      __dump_folder(of, orphans[:folders])
    }
    orphans[:folders].each { |of|
      of.delete(:parent) if of[:parent] == f.id
    }

    general_folder = { id: 0, title: "None", pages: [] }
    f.pages.each { |p|
      general_folder[:pages] << p.serialize.delete!(:folder)
    }

    orphans[:folders] << general_folder
  end

  unless f.destroy
    halt 500, f.collect_errors
  end

  # if parent
  #   return { folders: [ parent.serialize ] }.to_json
  # else
  #   return orphans.to_json
  # end

  # yeah, extremely inefficient, but bullet-proof and requires no extra logic
  current_user.all_pages.to_json
end

get '/folders/new', :auth => :user do
  erb :"/folders/new", layout: !request.xhr?
end

get '/groups/:gid/folders/new', :auth => :group_editor do |gid|
  erb :"/folders/new", layout: !request.xhr?
end

# User folder creation
post '/folders', :auth => :user do
  create_folder
end

# Group folder creation
post '/groups/:gid/folders', :auth => :group_editor do |gid|
  create_folder(gid)
end

# User folder update
put '/folders/:id', :auth => :user do |folder_id|
  update_folder(folder_id)
end

# Group folder update
put "/groups/:gid/folders/:id", :auth => :group_editor do |gid, id|
  update_folder(id, gid)
end

# User page to folder addition
put '/folders/:gid/add/:page_id', :auth => :user do |fid, pid|
  add_to_folder(fid, pid)
end

# Group page to folder addition
put '/groups/:gid/folders/:id/add/:page_id', :auth => :group_editor do |gid, fid, pid|
 add_to_folder(fid,pid,gid)
end

# User folder deletion
delete '/folders/:id', :auth => [ :user ] do |fid|
  delete_folder(fid)
end

# Group folder deletion
delete '/groups/:gid/folders/:id', :auth => :group_editor do |gid, fid|
  delete_folder(fid, gid)
end