require 'lib/strategies/pagehub'
require 'lib/strategies/facebook'

class Session < PageHub

  # facebook callback
  def facebook
    warden.authenticate!(:facebook)
    return login!
  end

  # Twitter callback
  # def twitter
  #   warden.authenticate!(:twitter)
  #   return login!
  # end  

  # # openid callback (yahoo, google)
  # def openid
  #   warden.authenticate!(:openid)
  #   return login!
  # end

  get '/' do
    erb :"/login"
  end

  post '/' do
    puts params.inspect
    env['warden'].authenticate!
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