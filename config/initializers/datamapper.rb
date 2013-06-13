configure do

  dbc = settings.database
  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "mysql://#{dbc[:un]}:#{dbc[:pw]}@#{dbc[:host]}/#{dbc[:db]}")


  puts ">> Database connection: "
  puts ">> \tAdapter: mysql"
  puts ">> \tHost: #{dbc[:host]}"
  puts ">> \tDatabase: #{dbc[:db]}"
  puts ">> \tUsername: #{dbc[:un]}"
  puts ">> \tPassword: #{dbc[:pw].length}"

  DataMapper.finalize
  DataMapper.auto_upgrade! unless $DB_BOOTSTRAPPING
end