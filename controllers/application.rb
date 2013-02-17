before do
  if api_call?    
    request.body.rewind
    body = request.body.read.to_s || ''
    unless body.empty?
      begin; params.merge!(JSON.parse(body)) rescue nil end
    end
  else
    @layout = "layouts/#{logged_in? ? 'primary' : 'guest' }".to_sym
  end
end

def on_api_error(msg = response.body)
  status response.status

  msg = case
  when msg.is_a?(String)
    [ msg ]
  when msg.is_a?(Array)
    msg
  when msg.is_a?(DataMapper::Validations::ValidationErrors)
    msg.to_hash.collect { |k,v| v }.flatten
  else
    [ "unexpected response: #{msg}" ]
  end
  
  {
    :status   => 'error',
    :messages => msg
  }
end

error Sinatra::NotFound do
  return if @internal_error_handled
  @internal_error_handled = true
  
    
  if api_call?
    content_type :json
    on_api_error("No such resource.").to_json
  else
    erb :"404", :layout => :"layouts/guest"
  end
end

[ 400, 401, 403, 404 ].each do |http_rc|
  error http_rc, :provides => [ :json, :html ] do
    return if @internal_error_handled
    @internal_error_handled = true
      
    respond_to do |f|
      f.html { erb :"#{http_rc}", :layout => :"layouts/guest" }
      f.json { on_api_error.to_json }
    end
  end
end

error 500 do
  return if @internal_error_handled
  @internal_error_handled = true
  
  if !settings.intercept_internal_errors
    raise request.env['sinatra.error']
  end
  
  begin
    courier.report_error(request.env['sinatra.error'])
  rescue Exception => e
    # raise e
  end
  
  respond_to do |f|
    f.html { erb :"500", :layout => :"layouts/guest" }
    f.json { on_api_error("Internal error").to_json }
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