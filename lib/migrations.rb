migration 1, :change_string_lengths do
  up do
    adapter = DataMapper.repository(:default).adapter
    # puts adapter.inspect
    namesz = 120
    { "users" => {
        "email" => 255,
        "name" => namesz,
        "nickname" => namesz,
        "password" => 64,
        "provider" => 255,
        "uid" => 255
      },
      "groups" => { "name" => namesz, "title" => namesz },
      "pages" => { "title" => 255, "pretty_title" => 255 }
    }.each_pair { |table, entries|
      entries.each_pair { |col, sz|
        query = "ALTER TABLE #{table} MODIFY COLUMN #{col} varchar(#{sz});"
        puts query
        adapter.execute(query)
      }
    }
  end

  down do
  end
end
