get '/groups' do
  restricted!
  erb :"/groups/index"
end

get '/groups/new' do
  restricted!

  erb :'/groups/new'
end

get "/groups/:name" do |name|
  restricted!

  unless @group = Group.first(name: name.to_s)
    halt 404, "There is no such group called #{name}."
  end

  halt 403, "You do not belong to this group." unless @group.has_member?(current_user)

  erb :"/groups/show"
end

get '/groups/:name/edit' do |name|
  restricted!

  unless @group = Group.first(name: name.to_s)
    halt 404, "There is no such group called #{name}."
  end

  halt 403, "You do not belong to this group." unless @group.has_member?(current_user)
  halt 403, "You are not an administrator of this group." unless @group.is_admin?(current_user)

  erb :"/groups/edit"
end

# Returns whether group name is available or not
post '/groups/name' do
  restricted!

  # we need this name to not break the route
  false.to_json if params[:name] == 'name'

  Group.first(name: params[:name].to_s.sanitize).nil?.to_json
end

post '/groups' do
  restricted!

  if Group.first(name: params[:name].to_s.sanitize) || params[:name] == 'name'
    flash[:error] = "That group name is unavailable."
    return redirect '/groups/new'
  end

  g = Group.create(name: params[:name].to_s.sanitize, title: params[:name], admin_id: current_user.id)

  params[:users] ||= []
  params[:users] << current_user.nickname
  params[:users].each { |nn| if u = User.first(nickname: nn) then g.users << u end }

  g.save

  params[:admins] ||= []
  params[:admins] << current_user.nickname
  params[:admins].each { |nn|
    user = User.first(nickname: nn)
    next if !user
    if membership = GroupUser.first({ group_id: g.id, user_id: user.id })
      membership.update({ is_admin: true })
    end
  }

  flash[:notice] = "Group created successfully."
  redirect :"/groups/#{g.name}"
end

post '/groups/:_' do |_|
  restricted!

  puts params.inspect
  name = params[:name].to_s.sanitize
  unless g = Group.first({ name: name })
    halt 400, "There is no such group named #{name}!"    
  end

  g.update!({ name: name })

  params[:admins] ||= []
  params[:admins] << current_user.nickname
  params[:admins] << g.admin.nickname # the group creator is always an admin

  params[:users] ||= []
  params[:users] << current_user.nickname
  params[:users] << g.admin.nickname # the group creator is always a user
  
  GroupUser.all({ group_id: g.id }).destroy
  params[:users].each { |nn| 
    if u = User.first(nickname: nn) then
      begin
        GroupUser.create({ group_id: g.id, user_id: u.id, is_admin: params[:admins].include?(nn) })
      rescue
      end
    end
  }

  g.save!

  flash[:notice] = "Group updated successfully."

  redirect :"/groups/#{g.name}/edit"
end