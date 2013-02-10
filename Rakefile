# Sample tasks using dm-migrations
# Roughly following Rails conventions, and mostly based on Padrino's dm:* tasks
#
# Cf. https://github.com/padrino/padrino-framework/blob/master/padrino-gen/lib/padrino-gen/padrino-tasks/datamapper.rb
#     https://github.com/datamapper/dm-rails/blob/master/lib/dm-rails/railties/database.rake
#

require 'rake'

# replace this with however your app configures DataMapper repositor(ies)
task :environment do
  if ARGV
    if ARGV.include?('db:create') || ARGV.include?('db:setup')
      $DB_BOOTSTRAPPING = true
    end
  end

  require File.expand_path('app', File.dirname(__FILE__))
end

task :default => :environment do
end

Dir.glob('lib/tasks/**/*.rake').each { |f| import f }