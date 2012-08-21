$ROOT ||= File.dirname(__FILE__)
$LOAD_PATH << $ROOT

gem 'sinatra'
gem 'sinatra-content-for'
gem 'sinatra-flash'
gem "data_mapper", ">=1.2.0"
gem 'redcarpet'
gem 'albino'
gem 'nokogiri'
gem 'warden'

require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'warden'
require 'data_mapper'
require 'dm-mysql-adapter'
require "digest/sha1"
require 'json'
require 'lib/common'
require 'lib/toc'
require 'lib/embedder'

class PageHub < Sinatra::Base
  helpers do
    module Preferences
      # mapping of displayable font names to actual CSS font-family names
      FontMap = { 
        "Proxima Nova" => "ProximaNova-Light",
        "Ubuntu" => "UbuntuRegular",
        "Ubuntu Mono" => "UbuntuMonoRegular",
        "Monospace" => "monospace, Courier New, courier, Mono",
        "Arial" => "Arial",
        "Verdana" => "Verdana",
        "Helvetica Neue" => "Helvetica Neue"
      }
    end
  end

  configure do
    helpers Sinatra::ContentFor
    register Sinatra::Flash

    # DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, 'mysql://root@localhost/notebook')

    # load the models and controllers
    ["models", "controllers"].each { |resources|
      Dir.glob("#{resources}/*.rb").each { |f| require f }
    }
    
    require './session'

    DataMapper.finalize
    DataMapper.auto_upgrade!

    set :default_preferences, JSON.parse(File.read(File.join($ROOT, "default_preferences.json")))
  end

  before do
    # CodeMirror theme
    @theme = @cm_theme = "neat"
  end

  get '/' do
    destination = "greeting"

    if logged_in?
      @pages = Page.all(user_id: current_user.id)
      destination = "index"
    end

    erb destination.to_sym
  end

  get '/tutorial' do
    erb :"/tutorial.md", layout: :"print_layout"
  end

  get '/markdown-cheatsheet' do
    erb :"/markdown-cheatsheet", layout: :"print_layout"
  end

  get '/testdrive' do
    erb :"/tutorial.md", layout: :"print_layout"
  end

  # not_found do
  #   erb :"404"
  # end

  error 403 do
    erb :"403"
  end
end


builder = Rack::Builder.new do
  Warden::Manager.serialize_into_session do |user|
    user.id
  end

  Warden::Manager.serialize_from_session do |id|
    User.get(id)
  end

  Warden::Manager.before_failure do |env,opts|
    # Sinatra is very sensitive to the request method
    # since authentication could fail on any type of method, we need
    # to set it for the failure app so it is routed to the correct block
    env['REQUEST_METHOD'] = "POST"
  end

  # use Rack::MethodOverride
  use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'
  use Warden::Manager do |manager|
    manager.default_strategies :pagehub
    manager.failure_app = Session
  end

  map '/session' do
    puts "Mapping to PageHub Authenticator"
    run Session
  end

  map '/' do
    puts "Mapping to PageHub"
    run PageHub
  end

  # PageHub.run!
end

Rack::Handler::Thin.run builder