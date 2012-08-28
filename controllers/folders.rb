get '/folders/new' do
  restricted!

  erb :"/folders/new"
end
get '/folders/new.js' do
  restricted!

  erb :"/folders/new", layout: false
end
get '/folders/:id/edit.js' do |folder_id|
  restricted!

  unless @f = current_user.folders.first({ id: folder_id })
    halt 404, "No folder with the id #{folder_id} exists."
  end

  erb :"/folders/edit", layout: false
end

# Create an empty folder, must be unique by title in the user's scope
post '/folders' do
  restricted!

  # folder title must not be empty nor taken
  # puts "Validating title emptiness"
  halt 400, "Folder title must not be empty" if !params[:title] || params[:title].empty?

  # puts "Validating title"
  pretty_title = params[:title].sanitize
  if current_user.folders.first({ pretty_title: pretty_title })
    halt 400, "That folder name is unavailable."
  end

  parent = nil
  if params[:folder_id] && params[:folder_id].to_i != 0 then
    parent = Folder.first({ id: params[:folder_id] })
    # puts "\tParent folder:#{parent.inspect}"
  end

  # puts "Creating folder"
  f = Folder.create!({ 
    title: params[:title], 
    pretty_title: pretty_title, 
    user_id: current_user.id,
    folder: parent
  })

  # puts f.inspect

  halt 501, "Unable to create folder #{params[:title]}." unless f

  f.to_json
end

# Update a folder's title
put '/folders/:id' do |folder_id|
  restricted!

  # puts params.inspect

  f = current_user.folders.first({ id: folder_id })

  halt 400, "That folder does not exist." unless f

  if params[:title].nil? || params[:title].empty? then
    # nothing to update
    return true.to_json
  end

  pretty_title = params[:title].sanitize
  if taken_folder = current_user.folders.first({ pretty_title: pretty_title })
    halt 400, "That folder name is unavailable." if taken_folder.id != f.id
  end

  parent = f.folder
  parent_id = params[:folder_id].to_i
  if parent_id == 0 then
    parent = nil
  else
    parent = Folder.first({ id: parent_id })
    halt 500, "No such parent folder with the id #{parent_id}" if !parent
    
    if parent.is_child_of?(f) then
      halt 500, "You cannot add the folder #{f.title} to #{parent.title}."
    end
    # puts "\tParent folder:#{parent.inspect}"
  end

  unless f.update({ title: params[:title], pretty_title: pretty_title, folder: parent })
    halt 500, "Something bad happened while updating folder."
  end

  f.to_json
end

# Add a page to this folder
put '/folders/:id/add/:page_id' do |folder_id, page_id|
  restricted!

  folder_id = folder_id.to_i

  # Folder#0 is special - it's the no-folder folder!
  if folder_id == 0 then
    unless p = current_user.pages.first({ id: page_id })
      halt 400, "That page does not exist."
    end

    p.update!({ folder_id: nil })
    return p.to_json
  end

  unless f = current_user.folders.first({ id: folder_id })
    puts "ERROR: Folder with id#{folder_id} doesn't exist!"
    halt 400, "That folder does not exist."
  end

  unless p = current_user.pages.first({ id: page_id })
    halt 400, "That page does not exist."
  end

  f.pages << p
  f.save

  p.to_json
end

# Remove a page from this folder
# put '/folders/:id/remove/:page_id' do |folder_id, page_id|
#   restricted!
#   unless f = current_user.folders.first({ id: folder_id })
#     halt 400, "That folder does not exist."
#   end

#   unless p = f.pages.first({ id: page_id })
#     halt 400, "That page is not inside that folder."
#   end

#   p.folder = nil
#   p.save

#   true.to_json
# end

delete '/folders/:id' do |folder_id|
  restricted!
  unless f = current_user.folders.first({ id: folder_id })
    halt 400, "That folder does not exist."
  end

  # puts "Deleting folder##{f.id}"
  rc = f.destroy
  # puts rc
  rc.to_json
end