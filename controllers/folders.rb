# Create an empty folder, must be unique by title in the user's scope
def create_folder(gid = nil)

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


get '/spaces/:space_id/folders/:folder_id',
  auth:     [ :member ],
  requires: [ :space, :folder ],
  provides: [ :json ] do
 
  authorize! :read, @folder, :message => "You need to be a member of this space to browse its folders."
  
  respond_with @folder do |f|
    f.json { rabl :"/folders/show" }
  end
end
  
post '/spaces/:space_id/folders',
  auth: [ :editor ],
  requires: [ :space ],
  provides: [ :json ] do

  authorize! :create, Folder, :message => "You need to be an editor in this space to create folders."

  api_required!({
    :title => nil
  })
  
  api_optional!({
    :parent_id  => lambda { |fid|
      "No such parent folder #{fid}" unless @parent = @space.folders.get(fid.to_i) }
  })
  
  api_consume! :parent_id
  
  @folder = @space.folders.new api_params({
    creator:  @user,
    folder:   @parent || @space.root_folder
  })
  
  unless @folder.save
    halt 400, @folder.errors
  end
  
  respond_with @folder do |f|
    f.json { rabl :"/folders/show" }
  end
end

# User folder update
put '/spaces/:space_id/folders/:folder_id',
  auth: [ :editor ],
  provides: [ :json ],
  requires: [ :space, :folder ] do
    
  authorize! :update, @folder, :message => "You need to be an editor in this space to edit folders."

  api_optional!({
    :title => nil,
    :parent_id  => lambda { |fid|
      "No such parent folder #{fid}" unless @parent = @space.folders.get(fid.to_i) }
  })
  
  api_consume! :parent_id
  
  unless @folder.update api_params({ folder: @parent || @folder.folder })
    halt 400, @folder.errors
  end
  
  respond_with @folder do |f|
    f.json { rabl :"/folders/show" }
  end
end


delete '/spaces/:space_id/folders/:folder_id',
  auth:     [ :admin ],
  provides: [ :json   ],
  requires: [ :space, :folder ] do
  
  authorize! :delete, @folder, :message => "You can not remove folders created by someone else."
  
  unless @folder.destroy
    halt 500, @folder.errors
  end
  
  respond_to do |f|
    f.html {
      flash[:notice] = "Folder has been removed."
      redirect back
    }
    f.json { halt 200 }
  end
end