before do
  if api_call?
    request.body.rewind
    params.merge!(JSON.parse(request.body.read.to_s))
  else
    @layout = "layouts/#{logged_in? ? 'primary' : 'guest' }".to_sym
  end
end

def on_api_error(msg = response.body)
  status response.status
  
  msg = case
  when msg.is_a?(String); [ msg ]
  when msg.is_a?(Array);  msg
  else;                   [ 'unexpected response' ]
  end
  
  {
    :status   => 'error',
    :messages => msg
  }
end

[ 400, 401, 403, 404 ].each do |http_rc|
  error http_rc, :provides => [ :json, :html ] do
    respond_to do |f|
      f.html { erb :"#{http_rc}" }
      f.json { on_api_error.to_json }
    end
  end
end

get '/' do
  destination = "static/greeting.md"
  layout = "layouts/guest"

  if logged_in?
    @pages = Page.all(user_id: current_user.id)
    destination = "pages/index"
    layout = "layout"
  end

  erb destination.to_sym, layout: layout.to_sym
end

%w(/tutorial /testdrive).each { |uri|
  send("get", uri, auth: :user) do
    erb :"static/tutorial.md", layout: :"layouts/print"
  end
}

# Legacy support
get '/account' do
  @legacy = true
  erb :"/shared/_nav_account_links"
end

get '/help' do
  @legacy = true
  erb :"/shared/_nav_help_links"
end

get '/features' do erb :"static/features.md" end
get '/about' do erb :"static/about.md" end
get '/open-source' do erb :"static/open_source.md" end
  
user do
  current_user
end

cancan_space do
  @space
end