source :rubygems

gem 'sinatra', '=1.4.0',
  :git => 'https://github.com/sinatra/sinatra'
gem 'sinatra-contrib',
  :git => 'https://github.com/sinatra/sinatra-contrib',
  :require => [ 'sinatra/content_for', 'sinatra/config_file' ]

gem 'sinatra-flash', :require => 'sinatra/flash'
gem 'mysql'
gem 'json'
gem "dm-core", ">=1.2.0"
gem "dm-serializer", ">=1.2.0"
gem "dm-migrations", ">=1.2.0", :require => [
  'dm-migrations',
  'dm-migrations/migration_runner'
]
gem "dm-validations", ">=1.2.0"
gem "dm-constraints", ">=1.2.0"
gem "dm-types", ">=1.2.0"
gem "dm-mysql-adapter", ">=1.2.0"
gem 'multi_json'
gem 'addressable'
gem 'diff-lcs', '1.1.3'
gem 'uuid'
gem 'gravatarify', ">= 3.1.0"
gem 'pagehub-markdown', '>=0.1.3', :require => 'pagehub-markdown'
# gem 'pagehub-markdown', '>=0.1.3', :require => 'pagehub-markdown', path: '~/Workspace/Projects/pagehub-markdown'
gem "pony"
gem 'omniauth'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
# gem 'omniauth-twitter', '0.0.9'

group :development do
  gem 'thin'
end

group :test do
  gem 'rake'
  gem 'rspec', '2.12'
  gem 'rack-test', :require => "rack/test"
end