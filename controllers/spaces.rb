get '/spaces', :auth => :user do
  erb :"/spaces/index"
end

get '/spaces/new', :auth => :user do
  erb :'/spaces/new'
end

get "/spaces/:space_id", auth: :member, requires: [ :space ] do
  erb :"/spaces/show"
end

get "/spaces/:space_id/dashboard", auth: :member, requires: [ :space ] do
  erb :"/spaces/dashboard"
end

[ "general" ].each { |domain|
  get "/spaces/:space_id/admin/#{domain}", auth: :admin, requires: [ :space ] do
    erb :"/spaces/admin/#{domain}"
  end
}


%w(
  publishing
  publishing/layout
  publishing/theme
  publishing/navigation_links
  publishing/custom_css
  memberships
  browsability
).each { |domain|
  get "/spaces/:gid/edit/#{domain}", auth: :space_admin do
    erb :"/spaces/settings/#{domain}"
  end
}

get '/spaces/:gid/edit', :auth => :space_admin do |name|
  redirect "#{@space.url '/edit/general'}"
end

get '/spaces/:name/destroy', :auth => :space_creator do |name|
  # we're doing the following in the controller because I just couldn't
  # get the before :destroy hook in the Group model to work...

  # disband all folder pages into a special "Orphan" folder for each user
  @space.users.each { |u|
    f = u.folders.create({ title: "Orphans: #{@space.title}" })
    @space.pages.all({ user: u }).each { |p|
      p.update!({ folder: f, space: nil })
    }

    f.save
  }

  @space.folders.destroy!
  GroupUser.all({ space: @space }).destroy

  unless @space.destroy!
    flash[:error] = "Group #{name} could not be destroyed: #{@space.collect_errors}"
    return redirect "/spaces/#{name}/edit"
  end

  flash[:notice] = "Group #{name} has been destroyed."

  redirect '/spaces'
end

# Returns whether space name is available or not
post '/spaces/name', :auth => :user do
  name_available?(params[:name]).to_json
end

def assign_memberships(s)

  params[:users] ||= {}
  params[:users].each_pair { |idx, user_info|
    next if idx.to_i == -1

    # the space creator can not be modified
    next if user_info[:nickname] == s.creator.nickname

    # validate the user's existence
    unless u = User.first(nickname: user_info[:nickname]) then
      flash[:error] = "No such user: #{user_info[:nickname]}"
      return redirect back
    end

    membership = s.add_with_role(u, user_info[:role].to_sym)
    
    

    # role = user_info[:role].to_sym
    # validate the role
    # unless Group::Roles.include?( role )
    #   flash[:error] = "Unrecognizable space member role #{user_info[:role]}."
    #   return redirect back
    # end

    # if gu.role != role
    #   # puts "Group #{g.name}: changing the role of space member" +
    #   #      "#{u.nickname} from #{gu.role.to_s} to #{user_info[:role]}"

    #   # if the member is an admin, only the space creator can change their role
    #   if gu.role == :admin && !g.is_creator?(current_user)
    #     flash[:error] = "You can not demote the member #{u.nickname}, only the space creator can do that."
    #   # only the space creator can promote others to admins
    #   elsif role == :admin && !g.is_creator?(current_user)
    #     flash[:error] = "You can not promote the member #{u.nickname} to become an administrator of this space. " +
    #                     "Only the space creator can do that."

    #   elsif current_user.id == u.id
    #     flash[:notice] = "You can not change your own space role."
    #   # it's ok, either promoting/demoting a member from/to editorial role
    #   else
    #     gu.role = role
    #     gu.save
    #   end
    # end

    # puts "#{u.nickname} is now a member of #{g.name} as a: #{gu.role.to_s}"
  }

end

# def assign_browsability(g)
#   bpages    = params[:browsable][:pages]
#   bfolders  = params[:browsable][:folders]

#   s.folders.all.each  { |r| r.update({ browsable: bfolders.include?(r.id.to_s) })}
#   s.pages.all.each    { |r| r.update({ browsable: bpages.include?(r.id.to_s) })}
# end

# Group creation

post '/spaces', :auth => :user do
    
  api_required!({ title: nil })
  api_optional!({ brief: nil, is_public: nil })
    
  s = @user.owned_spaces.create(api_params)

  unless s.saved?
    halt 400, s.all_errors
  end  
    
  respond_to do |f|
    f.html do
      flash[:notice] = "Space created successfully."
      redirect s.url
    end

    f.json do
      rabl :"spaces/show", object: s
    end    
  end
end

put "/spaces/:space_id",
  auth:     :creator,
  provides: [ :json, :html ],
  requires: [ :space ] do
  
  authorize! :update, @space, message: "You need to be an admin of this space to update it."
  
  api_optional!({
    title:      nil,
    brief:      nil,
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
  
  api_consume!(:browsability) do |browsability_map|
    pages    = browsability_map[:pages]
    folders  = browsability_map[:folders]

    @space.folders.all.each  { |r| r.update!({ browsable: folders.include?(r.id.to_s) })}
    @space.pages.all.each    { |r| r.update!({ browsable: pages.include?(r.id.to_s) })}
  end
  
  api_consume!(:memberships) do |memberships|
    memberships.each { |m|
      # the space creator can not be modified

      # validate the user's existence
      unless u = User.first(nickname: m[:nickname]) then
        halt 400, "Membership error: no such user '#{m[:nickname]}'"
      end
      
      if u == @space.creator
        halt 403, "You can not modify the space creator's membership!"
      elsif u == current_user
        halt 403, "You can not modify your own space membership!"
      end

      if !m[:role]
        authorize! :kick, u, message: "You can not kick #{@space.role_of(u).to_s.to_plural} in this space."
        
        @space.kick(u)
        next
      end
      
      if @space.member?(u)
        if SpaceUser.weight_of(m[:role]) <= SpaceUser.weight_of(@space.role_of(u))
          authorize! :demote, [ u, m[:role] ], message: 'You can not demote that member.'
        else
          authorize! :promote, [ u, m[:role] ], message: 'You can not promote that member.'
        end
      else
        authorize! :invite, [ u, m[:role] ], message: "You can not add #{m[:role].to_s.to_plural} to this space."
      end
            
      # puts "adding a #{m[:role]} to #{@space.id}: #{u.nickname}"
      @space.add_with_role(u, m[:role].to_sym)
    }
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

put "/spaces/:space_id/memberships",
  auth:     :admin,
  provides: [ :json, :html ],
  requires: [ :space ] do
  
  authorize! :update, @space, message: "You must be an admin of this space to manage its memberships."
  
  assign_memberships(@space)

  if @space.save
    flash[:notice] = "Group updated successfully."
  else
    flash[:error] = "Unable to update space: #{@space.collect_errors}"
  end

  redirect "#{@space.url('/edit/memberships')}".to_sym
end

post "/spaces/:gid/edit/publishing/:scope", auth: :space_admin do |gid, scope|

  puts params.inspect
  
  # prefs = preferences(@space)
  prefs = @space.preferences
  prefs["publishing"]             ||= {}
  prefs["publishing"][scope.to_s] ||= {}
  prefs["publishing"][scope.to_s] = params[scope.to_s]
  puts prefs.inspect
  
  if scope == 'navigation_links'
    prefs["publishing"][scope.to_s].reject! { |e|
      !e["uri"] || e["uri"].empty? || !e["title"] || e["title"].empty?
    }
  end
  
  @space.settings = prefs.to_json.to_s
  # if params[:css]
    # @space.css = params[:css]
  # end

  if @space.save
    flash[:notice] = "Group updated successfully."
  else
    flash[:error] = "Unable to update space: #{@space.collect_errors}"
  end

  redirect back
end

post "/spaces/:gid/edit/browsability", auth: :space_admin do |gid|
  assign_browsability(@space)

  if @space.save
    flash[:notice] = "Group updated successfully."
  else
    flash[:error] = "Unable to update space: #{@space.collect_errors}"
  end

  redirect "#{@space.url('/edit/browsability')}".to_sym
end

# post '/spaces/:current_name', :auth => :space_admin do |current_name|
#   g = @space

#   puts params.inspect

#   name_changed = params[:name] && !params[:name].empty? && params[:name].to_s.sanitize != current_name

#   # Only the space creator can change its name
#   if g.is_master_admin?(current_user)
#     if name_changed
#       if !name_available?(params[:name])
#         flash[:error] = "That space name is unavailable."
#         return redirect back
#       end

#       if !params[:confirmed] || !params[:confirmed] == "do it" then
#         flash[:error] = "Will not modify the space name until you confirm your action."
#       else
#         g.title = params[:name]
#       end
#     end

#     g.is_public = params[:is_public] == "true"
#     g.css = params[:css]
#   else
#     if name_changed
#       flash[:error] = "Only the space creator can change its name."
#     end
#   end

#   assign_memberships(g)

#   assign_browsability(g)

#   if g.save
#     flash[:notice] = "Group updated successfully."
#   else
#     flash[:error] = "Unable to update space: #{g.collect_errors}"
#   end

#   redirect :"/spaces/#{g.name}/edit"
# end

put '/spaces/:gid/kick/:id', :auth => :space_admin do |gid, user_id|
  id = user_id.to_i
  unless gu = @scope.space_users.first({ user_id: id })
    halt 400, "No such user: #{id}"
  end

  if gu.role == :admin && !@scope.is_creator?(current_user)
    halt 403, "Only the space creator can kick admins."
  end

  if @scope.is_creator?(gu.user)
    halt 403, "Group creator can't be kicked!"
  end

  # puts "Removing member #{id} from space #{@scope.name}"
  gu.destroy

  true
end

get '/spaces/:gid/leave', :auth => :space_member do |gid|
  unless gu = @scope.space_users.first({ user: current_user })
    halt 400, "No such membership."
  end

  if @scope.is_creator?(current_user)
    flash[:error] = "You can not leave a space you've created!"
    return redirect back
  end

  gu.destroy

  flash[:notice] = "You are no longer a member of the space #{@scope.name}"

  redirect back
end