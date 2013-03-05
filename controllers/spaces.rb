get '/users/:user_id/spaces',
  auth: [ :user ],
  requires: [ :user ],
  provides: [ :json, :html ],
  exclusive: true do

  authorize! :read, @space, message: "You do not have access to that user's spaces."

  respond_with @user do |f|
    f.html { erb :"spaces/index" }
    f.json { rabl :"spaces/index", collection: @user.spaces }
  end
end

get '/new',
  auth: [ :user ],
  # requires: [ :user ],
  provides: [ :html ] do

  # authorize! :create, Space, message: "You can not create new spaces."
  @user  = current_user
  @space = current_user.spaces.new

  respond_with @space do |f|
    f.html { erb :'/spaces/new' }
  end
end

get "/users/:user_id/spaces/:space_id.?:format",
  auth: [ :member ],
  provides: [ :json, :zip ],
  requires: [ :user, :space ] do

  authorize! :access, @space, message: "You do not have access to that space."

  if params[:format] && params[:format] == 'zip'
    serializer = PageHub::SpaceSerializer.new
    archive = serializer.serialize(@space, settings.space_archives, :zip, true)
    return send_file archive, {
      filename: File.basename(archive),
      disposition: 'attachment'
    }
  end

  respond_with @space do |f|
    f.json { rabl :"/spaces/show", object: @space }
  end
end

get "/users/:user_id/spaces/:space_id/dashboard", auth: :member, requires: [ :user, :space ] do
  erb :"/spaces/dashboard"
end

# get "/users/:user_id/spaces/:space_id/edit",
#   auth: [ :admin ],
#   requires: [ :user, :space ],
#   provides: [ :html  ] do

#   authorize! :update, @space, message: "You must be an admin of this space to manage it."

#   respond_with @space do |f|
#     f.html { erb :"/spaces/settings/index" }
#   end
# end

delete '/users/:user_id/spaces/:space_id',
  auth: [ :creator ],
  requires: [ :user, :space ],
  provides: [ :json  ] do

  authorize! :delete, @space, message: "Only the space creator can do that."

  unless @space.destroy
    halt 400, @space.all_errors
  end

  respond_to do |f|
    f.json do
      halt 200, {}.to_json
    end
  end
end

# Returns whether space name is available or not
post '/users/:user_id/spaces/name',
  auth: [ :user ],
  provides: [ :json ],
  requires: [ :user ],
  exclusive: true do

  respond_to do |f|
    f.json { { available: name_available?(params[:name]) }.to_json }
  end
end

post '/users/:user_id/spaces',
  auth: [ :user ],
  requires: [ :user ],
  provides: [ :html, :json ],
  exclusive: true  do

  api_required!({ title: nil })
  api_optional!({ brief: nil, is_public: nil })

  @space = @user.owned_spaces.create(api_params)

  unless @space.saved?
    halt 400, s.all_errors
  end

  respond_to do |f|
    f.html do
      flash[:notice] = "Space created successfully."
      redirect @space.url
    end

    f.json do
      rabl :"spaces/show", object: @space
    end
  end
end

put "/users/:user_id/spaces/:space_id",
  auth:     :admin,
  provides: [ :json, :html ],
  requires: [ :user, :space ] do

  authorize! :update, @space, message: "You need to be an admin of this space to update it."

  api_optional!({
    title:      nil,
    brief:      nil,
    preferences: nil,
    is_public:  nil,
    memberships: lambda { |ms|
      unless ms.is_a?(Array)
        "[memberships] must be an array of memberships"
      end
    },
    browsability: lambda { |b|
      unless b.is_a?(Hash) && b.has_key?('pages') && b.has_key?('folders')
        "[browsability] must be hash of :pages and :folders"
      end
    }
  })

  if api_has_param?(:title)
    authorize! :update_meta, @space, message: "Only the space creator can do that."
  end

  # api_consume!(:browsability) do |browsability_map|
  #   pages    = browsability_map[:pages]
  #   folders  = browsability_map[:folders]

  #   @space.folders.all.each  { |r| r.update!({ browsable: folders.include?(r.id.to_s) })}
  #   @space.pages.all.each    { |r| r.update!({ browsable: pages.include?(r.id.to_s) })}
  # end

  api_consume!(:memberships) do |memberships|
    memberships.each { |m|
      # the space creator can not be modified

      m[:role], m[:user_id] = m['role'], m['user_id']

      # validate the user's existence
      unless u = User.get(m[:user_id]) then
        halt 400, "Membership error: no such user '#{m[:user_id]}'"
      end

      if u == @space.creator
        halt 403, "You can not modify the space creator's membership!"
      elsif u == current_user && !m[:role].nil?
        halt 403, "You can not modify your own space membership!"
      end

      if !m[:role]
        authorize! :kick, [ @space, u ], message: "You can not kick #{@space.role_of(u).to_s.to_plural} in this space."

        @space.kick(u)
        next
      end

      if @space.member?(u)
        if SpaceUser.weight_of(m[:role]) <= SpaceUser.weight_of(@space.role_of(u))
          authorize! :demote, [ @space, u, m[:role] ], message: 'You can not demote that member.'
        else
          authorize! :promote, [ @space, u, m[:role] ], message: 'You can not promote that member.'
        end
      else
        authorize! :invite, [ @space, u, m[:role] ], message: "You can not add #{m[:role].to_s.to_plural} to this space."
      end

      # puts "adding a #{m[:role]} to #{@space.id}: #{u.nickname}"
      @space.add_with_role(u, m[:role].to_sym)
    }
  end

  api_consume! :preferences do |prefs|
    @space.save_preferences(@space.preferences.deep_merge(prefs))
  end

  unless @space.update(api_params)
    halt 400, @space.all_errors
  end

  respond_to do |f|
    f.html {
      flash[:notice] = "Space updated successfully."
      redirect back
    }

    f.json {
      rabl :"spaces/show", object: @space
    }
  end
end