# Create an empty folder, must be unique by title in the user's scope
def create_folder(gid = nil)
  r = @group || current_user

  # folder title must not be empty nor taken
  # puts "Validating title emptiness"
  halt 400, "Folder title must not be empty" if !params[:title] || params[:title].empty?

  # puts "Validating title"
  pretty_title = params[:title].sanitize
  if r.folders.first({ pretty_title: pretty_title })
    halt 400, "That folder name is unavailable."
  end

  parent = nil
  if params[:folder_id] && params[:folder_id].to_i != 0 then
    parent = r.folders.first({ id: params[:folder_id] })

    halt 400, "No such parent folder with the id #{parent_id}" if !parent
  end

  f = r.folders.create({ 
    title: params[:title], 
    pretty_title: pretty_title, 
    user: current_user,
    folder: parent
  })

  halt 501, "Unable to create folder #{params[:title]}." unless f
  f.to_json
end

# Updates the folder's title and its parent containing folder
def update_folder(fid, gid = nil)
  r = @group || current_user

  unless f = r.folders.first({ id: fid })
    halt 400, "That folder does not exist."
  end

  # doesn't want to update the title
  if !params[:title].nil? && !params[:title].empty? then
    pretty_title = params[:title].sanitize
    if taken_folder = r.folders.first(pretty_title: pretty_title, :id.not => f.id)
      halt 400, "That folder name is unavailable."
    end

    f.title = params[:title]
    f.pretty_title = pretty_title
  end

  parent_id = params[:folder_id].to_i
  if parent_id == 0 then
    f.folder = nil # has detached the folder from its parent
  else
    unless parent = r.folders.first(id: parent_id)
      halt 500, "No such parent folder with the id #{parent_id}"
    end
    
    if parent.id == f.id || parent.is_child_of?(f) then
      halt 500, "You cannot add the folder #{f.title} to #{parent.title}."
    end

    f.folder = parent
  end

  unless f.save
    halt 500, "Something bad happened while updating the folder."
  end

  f.to_json
end

# Add a page to this folder
def add_to_folder(fid, pid, gid = nil)
  r = @group || current_user

  unless p = r.pages.first(id: pid)
    halt 400, "That page does not exist."
  end

  # Folder#0 is special - it's the no-folder folder!
  if fid.to_i == 0 then
    unless p.update(folder: nil)
      halt 500, "Unable to update that page."
    end

    return p.to_json
  end

  unless f = r.folders.first(id: fid)
    halt 400, "That folder does not exist."
  end

  f.pages << p
  
  unless f.save
    halt 500, "Unable to update the page."
  end

  p.to_json  
end

def delete_folder(fid, gid = nil)
  r = @group || current_user

  unless f = r.folders.first({ id: fid })
    halt 400, "That folder does not exist."
  end

  f.state = { user: current_user, group: @group }

  # unless f.deletable_by? current_user
  #   halt 403, f.errors
  # end

  unless f.destroy
    halt 500, "#{f.collect_errors}" 
  end

  true
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
put '/folders/:id/add/:page_id', :auth => :user do |folder_id, page_id|
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