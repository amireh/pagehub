get '/auth/failure', provides: [ :html ] do
  flash[:error] = params[:message]
  redirect '/'
end

get '/sessions/new', auth: [ :guest ], provides: [ :html ] do
  erb :"/sessions/new"
end

# post '/sessions', :provides => [ :json, :html ] do
post '/sessions', auth: :guest, :provides => [ :json, :html ] do

  if u = authenticate(params[:email], params[:password])
    authorize(u)
  end

  respond_to do |f|
    f.html {
      unless u
        flash[:error] = "Incorrect credentials, please try again."
        return redirect back
      end

      redirect '/'
    }

    f.json do
      if logged_in?
        halt 200, {}.to_json
      else
        halt 401
      end
    end
  end
end

delete '/sessions', auth: [ :user ], provides: [ :json, :html ] do

  if demo = current_user.demo?
    current_user.destroy
  end

  session[:id] = nil

  respond_to do |f|
    f.html {
      if demo
        flash[:notice] = "Thanks for trying out PageHub, we hope you come back!"
      else
        flash[:notice] = "Successfully logged out."
      end

      redirect '/'
    }

    f.json { halt 200, {}.to_json }
  end
end

# Support both GET and POST for callbacks
%w(get post).each do |method|
  send(method, "/auth/:provider/callback") do |provider|
    auth = env['omniauth.auth']

    # create the user if it's their first time
    unless u = User.first({ uid: auth.uid, provider: provider, name: auth.info.name })

      uparams = { uid: auth.uid, provider: provider, name: auth.info.name }
      uparams[:email] = auth.info.email

      if !uparams[:email] || !uparams[:email].is_a?(String) || uparams[:email].empty?
        flash[:error] = "The 3rd-party provider did not provide us with your email, we can not create your PageHub account."
        return redirect "/"
      end

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
        uparams[:nickname] = "#{nickname}_#{tiny_salt}"
        uparams[:auto_nickname] = true
      end

      # puts "Creating a new user from #{provider} with params: \n#{uparams.inspect}"
      u = User.create(uparams)
      if u then
        flash[:notice] = "Welcome to PageHub! You have successfully signed up using your #{provider} account."
      else
        flash[:error] = "Sorry! Something wrong happened while signing you up. Please try again."
        return redirect "/"
      end
    end

    authorize(u)

    redirect '/'
  end
end
