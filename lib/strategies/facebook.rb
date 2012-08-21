require 'oauth2'

Warden::Strategies.add(:facebook) do
  Key = '317802154982714'
  Secret = 'de92a9d125c1505f17d3e2d0faf384ef'

  def valid?
    puts "Validating Facebook login: #{params.inspect}"
    params["facebook"] or params["code"] or params["error_reason"]
  end

  def client
    OAuth2::Client.new(Key, Secret, :site => 'https://graph.facebook.com')
  end 

  def redirect_to_facebook
    redirect! client.web_server.authorize_url(:redirect_uri => redirect_uri,
                                              :scope => 'email')
  end

  
  def authenticate!
    puts "Authenticating with the Facebook strategy"

    # First Time
    return redirect_to_facebook if params["facebook"] 
    # What a jackass
    return fail!('You have not accepted to assign your acount with pagehub.org') if params["error_reason"]

    access_token = client.web_server.get_access_token(params["code"], :redirect_uri => redirect_uri)  
    fb_user = JSON.parse(access_token.get('/me', :fields =>'id,link,email,picture,gender'))
    id = "fb:#{fb_user['id']}"
    unless u = User.find_by_identity_url(id)
      uname = fb_user['link'].split('/').last
      uname = fb_user['email'].split('@').first if uname =~ /^profile/

      # Create the user
      User.create :username => uname
      
    end
    success! u
  end

  def redirect_uri  
    uri = URI.parse(request.url)
    uri.path = '/users/facebook'  
    uri.query = nil
    uri.to_s
  end  

  
end