source :rubygems

gem 'sinatra'
gem 'sinatra-contrib', :require => 'sinatra/content_for'
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
gem 'redcarpet'
gem 'albino'
gem 'nokogiri'
gem 'multi_json'
gem 'addressable'
gem 'diff-lcs'
gem 'uuid'
gem 'gravatarify', ">= 3.1.0"

group :development do
  gem 'thin'
end

group :production do
  gem "pony"
  gem 'omniauth'
  gem 'omniauth-facebook'
  gem 'omniauth-github'
  gem 'omniauth-twitter', '0.0.9'
end