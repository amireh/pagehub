get '/groups', :auth => :user do
  erb :"/groups/index"
end

get '/groups/new', :auth => :user do
  erb :'/groups/new'
end

get "/groups/:name", :auth => :group_member do |name|
  erb :"/groups/show"
end

get "/groups/:name/info", :auth => :group_member do |name|
  erb :"/groups/info"
end

get "/groups/:name/space", :auth => :group_member do |name|
  erb :"/groups/public"
end

get '/groups/:name/edit', :auth => :group_admin do |name|
  erb :"/groups/edit"
end

get '/groups/:name/destroy', :auth => :group_creator do |name|
  # we're doing the following in the controller because I just couldn't
  # get the before :destroy hook in the Group model to work...

  # disband all folder pages into a special "Orphan" folder for each user
  @group.users.each { |u|
    f = u.folders.create({ title: "Orphans: #{@group.title}" })
    @group.pages.all({ user: u }).each { |p|
      p.update!({ folder: f, group: nil })
    }

    f.save
  }

  @group.folders.destroy!
  GroupUser.all({ group: @group }).destroy

  unless @group.destroy!
    flash[:error] = "Group #{name} could not be destroyed: #{@group.collect_errors}"
    return redirect "/groups/#{name}/edit"
  end

  flash[:notice] = "Group #{name} has been destroyed."

  redirect '/groups'
end


# Returns whether group name is available or not
post '/groups/name', :auth => :user do
  name_available?(params[:name]).to_json
end

def assign_memberships(g)

  params[:users] ||= {}
  params[:users].each_pair { |idx, user_info|
    next if idx.to_i == -1

    # the group creator can not be modified
    next if user_info[:nickname] == g.creator.nickname

    # validate the user's existence
    unless u = User.first(nickname: user_info[:nickname]) then
      flash[:error] = "No such user: #{user_info[:nickname]}"
      return redirect back
    end

    gu = GroupUser.first_or_create({ group: g, user: u })

    role = user_info[:role].to_sym
    # validate the role
    unless Group::Roles.include?( role )
      flash[:error] = "Unrecognizable group member role #{user_info[:role]}."
      return redirect back
    end

    if gu.role != role
      # puts "Group #{g.name}: changing the role of group member" +
      #      "#{u.nickname} from #{gu.role.to_s} to #{user_info[:role]}"

      # if the member is an admin, only the group creator can change their role
      if gu.role == :admin && !g.is_creator?(current_user)
        flash[:error] = "You can not demote the member #{u.nickname}, only the group creator can do that."
      # only the group creator can promote others to admins
      elsif role == :admin && !g.is_creator?(current_user)
        flash[:error] = "You can not promote the member #{u.nickname} to become an administrator of this group. " +
                        "Only the group creator can do that."

      elsif current_user.id == u.id
        flash[:notice] = "You can not change your own group role."
      # it's ok, either promoting/demoting a member from/to editorial role
      else
        gu.role = role
        gu.save
      end
    end

    # puts "#{u.nickname} is now a member of #{g.name} as a: #{gu.role.to_s}"
  }

end

post '/groups', :auth => :user do
  back_url = "/groups/new"

  if params[:name].to_s.empty?
    flash[:error] = "Group name must be specified."
    return redirect back
  elsif !name_available?(params[:name])
    flash[:error] = "That group name is unavailable."
    return redirect back
  end

  unless g = Group.new({ title: params[:name], is_public: params[:is_public], admin: current_user })
    flash[:error] = "Group could not be created, please try again."
    return redirect back
  end

  assign_memberships(g)

  unless g.save
    flash[:error] = "Group could not be created: #{g.collect_errors}"
    GroupUser.all({ group: g.id }).destroy!
  end

  flash[:notice] = "Group created successfully."

  redirect :"/groups/#{g.name}"
end

post '/groups/:current_name', :auth => :group_admin do |current_name|
  g = @group

  name_changed = params[:name] && !params[:name].empty? && params[:name].to_s.sanitize != current_name

  # Only the group creator can change its name
  if g.is_master_admin?(current_user)
    if name_changed
      if !name_available?(params[:name])
        flash[:error] = "That group name is unavailable."
        return redirect back
      end

      if !params[:confirmed] || !params[:confirmed] == "do it" then
        flash[:error] = "Will not modify the group name until you confirm your action."
      else
        g.title = params[:name]
      end
    end

    g.is_public = params[:is_public] == "true"
    g.css = params[:css]
  else
    if name_changed
      flash[:error] = "Only the group creator can change its name."
    end
  end

  assign_memberships(g)

  if g.save
    flash[:notice] = "Group updated successfully."
  else
    flash[:error] = "Unable to update group: #{g.collect_errors}"
  end

  redirect :"/groups/#{g.name}/edit"
end

put '/groups/:gid/kick/:id', :auth => :group_admin do |gid, user_id|
  id = user_id.to_i
  unless gu = @scope.group_users.first({ user_id: id })
    halt 400, "No such user: #{id}"
  end

  if gu.role == :admin && !@scope.is_creator?(current_user)
    halt 403, "Only the group creator can kick admins."
  end

  # puts "Removing member #{id} from group #{@scope.name}"
  gu.destroy

  true
end

get '/groups/:gid/leave', :auth => :group_member do |gid|
  unless gu = @scope.group_users.first({ user: current_user })
    halt 400, "No such membership."
  end

  if @scope.is_creator?(current_user)
    flash[:error] = "You can not leave a group you've created!"
    return redirect back
  end

  gu.destroy

  flash[:notice] = "You are no longer a member of the group #{@scope.name}"

  redirect back
end