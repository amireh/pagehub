# encoding: UTF-8

$ROOT ||= File.dirname(__FILE__)
$LOAD_PATH << $ROOT

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

require 'config/constants'
require 'lib/common'

configure :development do
  Bundler.require(:development)
end

configure do
  # enable :sessions
  use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'

  helpers Gravatarify::Helper

  # Gravatarify.options[:default] = "wavatar"
  Gravatarify.options[:filetype] = :png
  Gravatarify.styles[:mini] = { size: 16, html: { :class => 'gravatar gravatar-mini' } }
  Gravatarify.styles[:default] = { size: 96, html: { :class => 'gravatar' } }
  Gravatarify.styles[:profile] = { size: 128, html: { :class => 'gravatar' } }

  dbc = JSON.parse(File.read(File.join($ROOT, 'config', 'database.json')))
  DataMapper.setup(:default, "mysql://#{dbc['username']}:#{dbc['password']}@localhost/#{dbc['db']}")

  # load the models and controllers
  def load(directory)
    Dir.glob("#{directory}/*.rb").each { |f| require f }
  end

  # Load the Markdown extensions
  # require "lib/markdown_ext/processor"
  # load "lib/markdown_ext"

  load "helpers"
  load "models"
  # load "controllers"
  require 'controllers/helpers'
  require 'controllers/groups'
  require 'controllers/users'
  require 'controllers/folders'
  require 'controllers/pages'

  require 'lib/migrations'

  DataMapper.finalize
  DataMapper.auto_upgrade!

  set :default_preferences, JSON.parse(File.read(File.join($ROOT, "default_preferences.json")))
end

configure :production do
  Bundler.require(:production)

  use OmniAuth::Builder do
    provider :developer if settings.development?
    provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
    provider :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET']
    # provider :google_oauth2, ENV['GOOGLE_KEY'], ENV['GOOGLE_SECRET'], { access_type: 'online', approval_prompt: '' }
    # provider :openid, :store => OpenID::Store::Filesystem.new(File.join($ROOT, 'tmp'))
  end

  Pony.options = {
    :from => "noreply@pagehub.org",
    :via => :smtp, :via_options => {
      :address => 'smtp.gmail.com',
      :port => '587',
      :enable_starttls_auto => true,
      :user_name => ENV['GMAIL_ID'],
      :password => ENV['GMAIL_PW'],
      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain => "HELO", # don't know exactly what should be here
    }
  }

end

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

get '/features' do
  erb :"static/features"
end

get '/about' do
  erb :"static/about"
end