$ROOT ||= File.dirname(__FILE__)
$LOAD_PATH << $ROOT

gem 'sinatra'
gem 'sinatra-content-for'
gem 'sinatra-flash'
gem "data_mapper", ">=1.2.0"
gem 'redcarpet'
gem 'albino'
gem 'nokogiri'
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'data_mapper'
require 'dm-mysql-adapter'
require "digest/sha1"
require 'json'
require 'lib/common'
require 'lib/toc'
require 'lib/embedder'
require 'omniauth'
require 'omniauth-facebook'
require 'omniauth-github'
require 'openid/store/filesystem' 

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
  # enable :sessions
  use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'
  use OmniAuth::Builder do
    provider :developer if settings.development?
    provider :facebook, ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
    # provider :openid, :store => OpenID::Store::Filesystem.new(File.join($ROOT, 'tmp'))
    # use OmniAuth::Strategies::Developer
  end

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, 'mysql://root@localhost/notebook')

  # load the models and controllers
  def load(directory)
    Dir.glob("#{directory}/*.rb").each { |f| require f }
  end

  load "models"
  load "controllers"

  DataMapper.finalize
  DataMapper.auto_upgrade!

  set :default_preferences, JSON.parse(File.read(File.join($ROOT, "default_preferences.json")))


  # p = {:uid=>"626495602", :provider=>"facebook", :name=>"Ahmad Amireh", :email=>"ahmad.amireh@gmail.com", :nickname=>"amireh.ahmad", 
    # :oauth_token=>"AAAEhChSOfToBAJsAoffiTVp1cZATBRaYQ0PQLAlRd8i8ZAbfZA2ftApxSu7ssSD9jHSIfcXa4kZBZBr1Gfx5cAh4zBkTxmnoalg5LhpHBaAZDZD", 
    # :extra=>"{\"id\":\"626495602\",\"name\":\"Ahmad Amireh\",\"first_name\":\"Ahmad\",\"last_name\":\"Amireh\",\"link\":\"http://www.facebook.com/amireh.ahmad\",\"username\":\"amireh.ahmad\",\"gender\":\"male\",\"email\":\"ahmad.amireh@gmail.com\",\"timezone\":3,\"locale\":\"en_US\",\"verified\":true,\"updated_time\":\"2012-08-21T05:10:57+0000\"}"}
  # User.create(p)
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

not_found do
  erb :"404"
end

error 403 do
  erb :"403"
end