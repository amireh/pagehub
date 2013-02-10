
not_found do
  # return "Bad link!".to_json if request.xhr?
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "404 - bad link!" : r.to_json
  end

  erb :"404"
end

error 403 do
  # return response.body.first.to_json if request.xhr?
  if request.xhr?
    r = response.body.first
    return r.include?("<html>") ? "403 - forbidden!" : r.to_json
  end

  erb :"403"
end

error do
  # return response.body.first.to_json if request.xhr?
  if request.xhr?
    halt 500, "500 - internal error: " + env['sinatra.error'].name + " => " + env['sinatra.error'].message
  end

  erb :"500"
end

before do
  @layout = "layouts/#{logged_in? ? 'primary' : 'guest' }".to_sym
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