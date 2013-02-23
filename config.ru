require 'bundler'
Bundler.require(:default)
require './app'

map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'app/assets/javascripts'
  environment.append_path 'app/assets/stylesheets'
  environment.append_path 'app/assets/templates'
  run environment
end

map '/' do
  run Sinatra::Application
end