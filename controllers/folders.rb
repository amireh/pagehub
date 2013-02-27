get '/spaces/:space_id/folders/new',
  auth: [ :member ],
  provides: [ :html ],
  requires: [ :space ] do

  respond_to do |f|
    f.html {
      options = {}
      options[:layout] = false if request.xhr?
      erb :"/folders/new", options
    }
  end
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

get '/spaces/:space_id/folders/:folder_id/edit',
  auth:     [ :editor ],
  provides: [ :html ],
  requires: [ :space, :folder ] do

  respond_to do |f|
    f.html {
      options = {}
      options[:layout] = false if request.xhr?
      erb :"/folders/new", options
    }
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
    :browsable => nil,
    :parent_id  => lambda { |fid|
      "No such parent folder #{fid}" unless @parent = @space.folders.get(fid.to_i) }
  })

  api_consume! :parent_id

  puts api_params.inspect

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
    f.json { halt 200, {}.to_json }
  end
end