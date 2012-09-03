require 'json'
require 'uuid'

private

def nickname_salt
  Base64.urlsafe_encode64(Random.rand(12345 * 1000).to_s)
end

public

before do
  if current_user && current_user.auto_nickname && flash.empty?
    flash[:notice] = "You have an auto-generated nickname, please go to your profile page and update it."
  end
end

get '/signup' do
  erb :"/users/new", layout: "layouts/guest".to_sym
end

post '/signup' do
  p = params
  
  # Validate input
  {
    "That email is already registered" => User.first(email: p[:email]),
    "You must fill in your name" => !p[:name] || p[:name].empty?,
    "You must type the same password twice" => p[:password].empty? || p[:password_confirmation].empty?,
    "The passwords you entered do not match" => p[:password] != p[:password_confirmation],
    "Passwords must be at least 5 characters long." => p[:password].length <= 4
  }.each_pair { |msg, cnd|
    if cnd then
      flash[:error] = msg
      return redirect "/signup"
    end
  }

  # Encrypt the password
  params[:password] = Digest::SHA1.hexdigest(params[:password])

  nickname = params[:name].to_s.sanitize
  auto_nn = false
  if User.first({ nickname: nickname }) then
    nickname = "#{nickname}_#{nickname_salt}"
    auto_nn = true
  end

  params.delete("password_confirmation")

  # Create the user with a UUID
  unless u = User.create!(params.merge({ uid: UUID.generate, nickname: nickname, auto_nickname: auto_nn, provider: "pagehub" }))
    flash[:error] = "Something bad happened while creating your new account, please try again."
    return redirect "/signup"
  end

  flash[:notice] = "Welcome to PageHub! Your new personal account has been registered."
  session[:id] = u.id

  redirect '/'
end

# Support both GET and POST for callbacks
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do |provider|
    auth = env['omniauth.auth']

    # create the user if it's their first time
    unless u = User.first({ uid: auth.uid, provider: provider, name: auth.info.name })
      
      uparams = { uid: auth.uid, provider: provider, name: auth.info.name }
      uparams[:email] = auth.info.email if auth.info.email
      uparams[:nickname] = auth.info.nickname if auth.info.nickname
      uparams[:oauth_token] = auth.credentials.token if auth.credentials.token
      uparams[:oauth_secret] = auth.credentials.secret if auth.credentials.secret
      if auth.extra.raw_info then
        uparams[:extra] = auth.extra.raw_info.to_json.to_s
      end

      fix_nickname = false
      nickname = ""

      # Make sure the nickname isn't taken
      if uparams.has_key?(:nickname) then
        if User.first({ nickname: uparams[:nickname] }) then
          nickname = uparams[:nickname] # just add the salt to it
          fix_nickname = true
        end
      else
        # Assign a default nickname based on their name
        nickname = auth.info.name.to_s.sanitize
      end

      if fix_nickname
        uparams[:nickname] = "#{nickname}_#{nickname_salt}"
        uparams[:auto_nickname] = true
      end

      # puts "Creating a new user from #{provider} with params: \n#{uparams.inspect}"
      u = User.create(uparams)
      if u then
        flash[:notice] = "Welcome to PageHub! You have successfully signed up using your #{provider} account."

        session[:id] = u.id

        return redirect '/'
      else
        flash[:error] = "Sorry! Something wrong happened while signing you up. Please try again."
        return redirect "/auth/#{provider}"
      end
    end

    # puts "User seems to already exist: #{u.id}"
    session[:id] = u.id

    redirect '/'
  end
end

get '/auth/failure' do
  flash[:error] = params[:message]
  redirect '/'
end

get '/login' do
  erb :"/login", layout: "layouts/guest".to_sym
end

post '/login' do
  pw = Digest::SHA1.hexdigest(params[:password])

  unless u = User.first({ password: pw, email: params[:email] })
    flash[:error] = "Incorrect email or password, please try again."
    return redirect "/login"
  end

  session[:id] = u.id
  redirect '/'
end


get '/logout' do
  session[:id] = nil

  flash[:notice] = "Successfully logged out."
  redirect :"/"
end

get '/settings' do
  restricted!
  
  erb :"/users/settings/index"
end

[ "account", "editing", "publishing", "profile", "notifications", "groups" ].each { |domain|
  get "/settings/#{domain}", auth: :user do
    erb :"/users/settings/#{domain}"
  end
}

get '/settings/skin/:skin' do |skin|
  restricted!

  if ["dark", "light"].include? skin
    curr_prefs = preferences
    curr_prefs["pagehub"] ||= {}
    curr_prefs["pagehub"]["skin"] = skin

    current_user.settings = curr_prefs.to_json
    if current_user.save
      flash[:notice] = "Switched to #{skin} skin."
    else
      flash[:error] = "Something wrong happened while updating your preferences."
    end
  else
    flash[:error] = "That skin is unavailable, try with 'light' or 'dark'"
  end

  redirect back
end

put '/profile/preferences/runtime', auth: :user do
  prefs = preferences
  prefs["runtime"] = params[:settings]

  puts "In runtime prefs. update:"
  puts params.inspect

  unless current_user.update({ settings: prefs.to_json.to_s })
    halt 500, current_user.collect_errors
  end

  true
end

post '/settings/password', auth: :user do
  pw = Digest::SHA1.hexdigest(params[:password][:current])

  if current_user.password == pw then
    pw_new = Digest::SHA1.hexdigest(params[:password][:new])
    pw_confirm = Digest::SHA1.hexdigest(params[:password][:confirmation])

    if params[:password][:new].empty? then
      flash[:error] = "You've entered an empty password!"
    elsif pw_new == pw_confirm then
      current_user.password = pw_new
      if current_user.save then
        flash[:notice] = "Your password has been changed."
      else
        flash[:error] = "Something bad happened while updating your password!"
      end
    else
      flash[:error] = "The passwords you've entered do not match!"
    end
  else
    flash[:error] = "The current password you've entered isn't correct!"
  end

  redirect back
end

post '/settings/nickname', auth: :user do
  # see if the nickname is available
  nickname = params[:nickname]
  if nickname.empty? then
    flash[:error] = "A nickname can't be empty!"
    return redirect back
  end

  u = User.first(nickname: nickname)
  # is it taken?
  if u && u.email != current_user.email then
    flash[:error] = "That nickname isn't available. Please choose another one."
    return redirect back
  end

  current_user.nickname = nickname
  current_user.auto_nickname = false

  if current_user.save then
    flash[:notice] = "Your nickname has been changed."
  else
    flash[:error] = "Something bad happened while updating your nickname."
  end

  redirect back
end

post "/settings/editing", auth: :user do
  # some preferences ought to be sanitized:
  # [editing][font_size] can't be 0 or over 30
  editing_fontsz = params[:settings][:editing][:font_size].to_i
  if editing_fontsz <= 0 then
    params[:settings][:editing][:font_size] = 8
  elsif editing_fontsz > 30 then
    params[:settings][:editing][:font_size] = 30
  end

  if params[:settings][:editing][:autosave] then
    params[:settings][:editing][:autosave] = true
  else
    params[:settings][:editing][:autosave] = false
  end
  
  prefs = preferences
  prefs["editing"] = params[:settings][:editing]
  current_user.settings = prefs.to_json.to_s

  if current_user.save then
    flash[:notice] = "Your editing preferences were updated."
  else
    flash[:error] = "Something bad happened while updating your editing preferences: #{current_user.collect_errors}."
  end

  redirect back
end

post "/settings/publishing", auth: :user do
  prefs = preferences
  prefs["publishing"] = params[:settings][:publishing]
  current_user.settings = prefs.to_json.to_s

  if current_user.save then
    flash[:notice] = "Your publishing preferences were updated."
  else
    flash[:error] = "Something bad happened while updating your publishing " +
                    "preferences: #{current_user.collect_errors}."
  end

  redirect back
end

post "/settings/profile", auth: :user do

  { :name => "Your name can not be empty",
    :email => "You must specify a primary email address.",
    :gravatar_email => "Your gravatar email address can not be empty."
  }.each_pair { |k, err|
    if !params[k] || params[k].empty?
      flash[:error] = err
      return redirect back
    else
      current_user.send("#{k}=".to_sym, params[k])
    end
  }

  # if !params[:name] || params[:name].empty?
  #   flash[:error] = "Your name can not be empty."
  #   return redirect back
  # elsif params[:name] != current_user.name
  #   current_user.name = params[:name]
  # end

  # if !params[:email] || params[:email].empty?
  #   flash[:error] = "You must specify an email address."
  #   return redirect back
  # elsif params[:email] != current_user.email
  #   current_user.email = params[:email]
  # end

  if current_user.save then
    flash[:notice] = "Your profile has been updated."
  else
    flash[:error] = current_user.collect_errors
  end

  redirect back
end

get '/users/nickname' do
  restricted!
  nn = params[:nickname]

  return [].to_json if nn.empty?

  nicknames = []
  User.all(:nickname.like => "#{nn}%", limit: 10).each { |u|
    nicknames << u.nickname
  }
  nicknames.to_json
end

# Returns whether params[:nickname] is available or not
post '/users/nickname', auth: :user do
  name_available?(params[:nickname]).to_json
end