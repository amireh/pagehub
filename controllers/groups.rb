get '/groups' do
  restricted!
  erb :"/groups/index"
end

get '/groups/new' do
  restricted!

  erb :'/groups/new'
end

%w(/:name /:name/edit).each do |uri|
  get "/groups#{uri}" do |name|
    restricted!

    unless @group = Group.first(name: name.to_s)
      halt 404, "There is no such group called #{name}."
    end

    halt 403, "You do not belong to this group." unless @group.has_member?(current_user)

    erb :"/groups/#{uri == '/:name/edit' ? 'edit' : 'show'}"
  end
end

get '/groups/:name/edit' do |name|
  restricted!

  unless @group = Group.first(name: name.to_s)
    halt 404, "There is no such group called #{name}."
  end

  halt 403, "You do not belong to this group." unless @group.has_member?(current_user)

  erb :"/groups/show"
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

  g = Group.create(name: params[:name].to_s.sanitize, title: params[:name])
  g.users << current_user

  (params[:users] || {}).each { |nn| if u = User.first(nickname: nn) then g.users << u end }

  g.save

  GroupUser.first({ group_id: g.id, user_id: current_user.id }).update({ is_admin: true })

  flash[:notice] = "Group created successfully."
  redirect :"/groups/#{g.name}"
end

post '/groups/:_' do |_|
  restricted!

  puts params.inspect
  name = params[:name]
  unless g = Group.first({ name: name })
    halt 400, "There is no such group named #{name}!"    
  end

  g.update({ name: name })
  g.users = [ current_user ]
  (params[:users] || []).each { |nn| if u = User.first(nickname: nn) then g.users << u end }
  g.save

  flash[:notice] = "Group updated successfully."

  redirect :"/groups/#{g.name}/edit"
end