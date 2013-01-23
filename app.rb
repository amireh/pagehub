# encoding: UTF-8

$ROOT ||= File.dirname(__FILE__)
$LOAD_PATH << $ROOT

Encoding.default_external = "UTF-8"

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default)

# ----
# Validating that configuration files exist and are readable...
config_files = [ 'application', 'database' ]
config_files << 'credentials' unless settings.test?
config_files.each { |config_file|
  unless File.exists?(File.join($ROOT, 'config', "%s.yml" %[config_file] ))
    class ConfigFileError < StandardError; end;
    raise ConfigFileError, "Missing required config file: config/%s.yml" %[config_file]
  end
}

require 'config/initializer'

configure :test do
  set :credentials, { 'cookie' => { 'secret' => 'adooken' } }
end

configure :development, :production do
  config_file 'config/credentials.yml'
end

configure do
  config_file 'config/application.yml'
  config_file 'config/database.yml'

  use Rack::Session::Cookie, :secret => settings.credentials['cookie']['secret']

  PageHub::Markdown::configure({}, { with_toc_data: true } )
  helpers Gravatarify::Helper

  # Gravatarify.options[:default] = "wavatar"
  Gravatarify.options[:filetype] = :png
  Gravatarify.styles[:mini] = { size: 16, html: { :class => 'gravatar gravatar-mini' } }
  Gravatarify.styles[:icon] = { size: 32, html: { :class => 'gravatar gravatar-icon' } }
  Gravatarify.styles[:default] = { size: 96, html: { :class => 'gravatar' } }
  Gravatarify.styles[:profile] = { size: 128, html: { :class => 'gravatar' } }

  dbc = settings.database
  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "mysql://#{dbc[:un]}:#{dbc[:pw]}@#{dbc[:host]}/#{dbc[:db]}")

  # load the models and controllers
  def load(directory)
    Dir.glob("#{directory}/*.rb").each { |f| require f }
  end

  [ 'lib', 'helpers', 'models' ].each { |d|
    Dir.glob("#{d}/**/*.rb").each { |f| require f }
  }
  require 'controllers/users'
  require 'controllers/folders'
  require 'controllers/groups'
  require 'controllers/pages'

  DataMapper.finalize
  DataMapper.auto_upgrade!

  set :default_preferences, JSON.parse(File.read(File.join($ROOT, "config/preferences.json")))
end

configure :production, :development do |app|
  use OmniAuth::Builder do
    provider :developer if app.settings.development?

    provider :facebook,
      app.settings.credentials['facebook']['key'],
      app.settings.credentials['facebook']['secret']
    # provider :twitter,  settings.credentials['twitter']['key'],  settings.credentials['twitter']['secret']

    provider :google_oauth2,
      app.settings.credentials['google']['key'],
      app.settings.credentials['google']['secret'],
      { access_type: "offline", approval_prompt: "" }

    provider :github,
      app.settings.credentials['github']['key'],
      app.settings.credentials['github']['secret']
  end

  Pony.options = {
    :from => settings.courier[:from],
    :via => :smtp,
    :via_options => {
      :address    => settings.credentials['courier']['address'],
      :port       => settings.credentials['courier']['port'],
      :user_name  => settings.credentials['courier']['key'],
      :password   => settings.credentials['courier']['secret'],
      :enable_starttls_auto => true,
      :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain => "HELO", # don't know exactly what should be here
    }
  }
end

configure :production do
  Bundler.require(:production)
end

configure :development do
  Bundler.require(:development)
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

get '/features' do erb :"static/features.md" end
get '/about' do erb :"static/about.md" end
get '/open-source' do erb :"static/open_source.md" end