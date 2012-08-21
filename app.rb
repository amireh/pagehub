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
gem 'ruby-openid'
gem 'rack-openid'

require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'warden'
require 'data_mapper'
require 'dm-mysql-adapter'
require "digest/sha1"
require 'json'
require 'openid'
require 'rack/openid'
require 'openid/store/filesystem'

require 'lib/common'
require 'lib/toc'
require 'lib/embedder'
require 'lib/main'

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

  use Rack::MethodOverride
  use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'
  use Rack::OpenID, OpenID::Store::Filesystem.new(File.join($ROOT, 'tmp/openid'))
  use Warden::Manager do |manager|
    manager.default_strategies :pagehub, :facebook
    manager.failure_app = Session
  end

  map '/session' do
    # puts "Mapping to PageHub Authenticator"
    run Session
  end

  map '/' do
    # puts "Mapping to PageHub"
    run PageHub
  end

  # PageHub.run!
end

Rack::Handler::Thin.run builder