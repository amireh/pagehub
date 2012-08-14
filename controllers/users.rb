require 'json'

class Hash

  # Merges self with another hash, recursively.
  # 
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  # 
  # Thanks to whoever made it.

  def deep_merge(hash)
    target = dup
    
    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end
      
      target[key] = hash[key]
    end
    
    target
  end
end

helpers do
  def logged_in?
    session[:authorized]
  end

  def current_user
    if @user then
      return @user
    end
    
    if !logged_in? then
      return nil
    end

    @user = User.first(email: session[:email])
    @user
  end

  def restricted!
    halt 401 unless logged_in?
  end

  def preferences
    @preferences ||= JSON.parse(current_user.settings || "{}")
    settings.default_preferences.deep_merge(@preferences)
    # set_defaults(settings.default_preferences, @preferences)
  end

end

get '/signup' do
  erb :"/users/new"
end

post '/signup' do
  if User.first(email: params[:email]) then
    flash[:error] = "That email is already registered!"
    return redirect "/signup"
  end

  params[:password] = Digest::SHA1.hexdigest(params[:password])

  u = User.create(params)
  if u then
    flash[:notice] = "Congratulations! Your new personal account has been registered."
  else
    flash[:error] = "Oops! We're sorry but something bad happened while creating your \
    new account, please try again."
    return redirect "/signup"
  end

  session[:authorized] = true
  session[:email] = u.email

  redirect '/'
end

get '/login' do
  erb :"/login"
end

post '/login' do
  pw = Digest::SHA1.hexdigest(params[:password])
  u = User.first({ password: pw, email: params[:email] })
  if u then
    session[:authorized] = true
    session[:email] = u.email
  else
    flash[:error] = "Incorrect email or password, please try again."
    return redirect "/login"
  end

  # flash[:notice] = "Welcome #{u.name.split.first}! You're now logged in."
  redirect '/'
end


get '/logout' do
  session[:authorized] = false
  session[:email] = nil

  flash[:notice] = "Bye!"
  redirect back
end

get '/profile' do
  restricted!
  
  erb :"/users/edit"
end

post '/profile/preferences' do
  restricted!

  # p params.inspect

  # see if the nickname is available
  nickname, u = params[:nickname], nil
  if nickname.empty? then
    flash[:error] = "A nickname can't be empty!"
  else
    u = User.first(nickname: nickname)
    if u && u.email != current_user.email then
      flash[:error] = "That nickname isn't available! Please choose another one."
    else
      current_user.nickname = nickname
    end
  end

  # some preferences ought to be sanitized:
  # [editing][font_size] can't be 0 or over 30
  editing_fontsz = params[:settings][:editing][:font_size].to_i
  if editing_fontsz <= 0 then
    params[:settings][:editing][:font_size] = 8
  elsif editing_fontsz > 30 then
    params[:settings][:editing][:font_size] = 30
  end

  current_user.settings = params[:settings].to_json

  if current_user.save then
    flash[:notice] = "Your preferences were updated!"
  else
    flash[:error] = "Something bad happened while updating your preferences :("
  end

  redirect :"/profile"
end

# Returns whether params[:nickname] is available or not
post '/users/nickname' do
  restricted!

  User.first(nickname: params[:nickname]).nil?.to_json
end

post '/profile/password' do
  restricted!

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
        flash[:error] = "Something bad happened while updating your password :("
      end
    else
      flash[:error] = "The passwords you've entered do not match!"
    end
  else
    flash[:error] = "The current password you've entered isn't correct!"
  end

  redirect :'/profile'
end