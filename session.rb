Warden::Strategies.add(:pagehub) do
  def valid?
    [ "email", "password" ].each { |field|
      if !params.has_key?(field) || params[field].empty? then
        return false
      end
    }
    true
  end

  def authenticate!
    puts "Authenticating user: #{params["email"]} with password #{params["password"]}"
    u = User.authenticate(params["email"], params["password"])
    u.nil? ? fail!("Login failed. Please verify your credentials and try again.") : success!(u)
  end
end

class Session < PageHub

  get '/' do
    erb :"login"
  end

  post '/' do
    env['warden'].authenticate!(:pagehub)
    flash[:success] = 'Successfully logged in!'
    redirect '/'
  end

  get '/destroy' do
    env['warden'].logout
    flash[:success] = "Logged out!"
    redirect '/'
  end

  delete '/' do
    env['warden'].logout
    flash[:success] = "Logged out!"
    redirect '/'
  end

  post '/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path]
    flash[:error] = env['warden'].message
    redirect to session[:return_to] || '/'
  end
 
  not_found do
    redirect '/' # catch redirects to GET '/session'
  end
end