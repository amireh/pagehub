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

get '/groups/:name/edit', :auth => :group_admin do |name|
  erb :"/groups/edit"
end

get '/groups/:name/destroy', :auth => :group_creator do |name|
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

post '/groups', :auth => :user do
  if params[:name].to_s.empty?
    flash[:error] = "Group name must be specified."
    return redirect '/groups/new'
  elsif !name_available?(params[:name])
    flash[:error] = "That group name is unavailable."
    return redirect '/groups/new'
  end

  unless g = Group.create({ title: params[:name], admin: current_user })
    flash[:error] = "Group could not be created, please try again."
    return redirect "/groups/new"
  end

  params[:admins] ||= []
  params[:users]  ||= []
  params[:admins] << current_user.nickname
  params[:users]  << current_user.nickname
  params[:users].uniq.each { |nn|
    if u = User.first(nickname: nn) then
      GroupUser.create({ group: g, user: u, is_admin: params[:admins].include?(nn) })
    end
  }

  g.save

  flash[:notice] = "Group created successfully."
  redirect :"/groups/#{g.name}"
end

post '/groups/:current_name', :auth => :group_admin do |current_name|
  g = @group

  name_changed = params[:name].to_s.sanitize != current_name

  # Only the group creator can change its name
  if g.is_master_admin?(current_user) 
    if name_changed && !name_available?(params[:name])
      flash[:error] = "That group name is unavailable."
      return redirect :"/groups/#{g.name}/edit"
    end

    g.title = params[:name]
  else
    if name_changed
      flash[:error] = "Only the group creator can change its name."
    end
  end

  params[:admins] ||= []

  # Has someone tried to demote the group creator? 
  if !params[:admins].include?(g.admin.nickname) &&
    # this because the current user isn't displayed in the form (they can't demote themselves)
    # so if the group creator is trying to update, they won't be in the list
    current_user.id != g.admin.id 
  then
    flash[:error] = "You can not demote the group creator '#{g.admin.nickname}'!"
  end

  params[:admins] << current_user.nickname
  params[:admins] << g.admin.nickname # the group creator is always an admin

  params[:users] ||= []
  params[:users] << current_user.nickname
  params[:users] << g.admin.nickname # the group creator is always a user
  
  GroupUser.all({ group_id: g.id }).destroy
  params[:users].each { |nn| 
    if u = User.first(nickname: nn) then
      begin
        GroupUser.create({ group: g, user: u, is_admin: params[:admins].include?(nn) })
      rescue
      end
    end
  }

  if g.save
    flash[:notice] = "Group updated successfully."
  else
    flash[:error] = "Unable to update group: #{g.collect_errors}"
  end

  redirect :"/groups/#{g.name}/edit"
end