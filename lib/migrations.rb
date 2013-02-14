# migration 1, :change_string_lengths do
#   up do
#     adapter = DataMapper.repository(:default).adapter
#     # puts adapter.inspect
#     # namesz = 120
#     # { "users" => {
#     #     "email" => 255,
#     #     "name" => namesz,
#     #     "nickname" => namesz,
#     #     "password" => 64,
#     #     "provider" => 255,
#     #     "uid" => 255
#     #   },
#     #   "groups" => { "name" => namesz, "title" => namesz },
#     #   "pages" => { "title" => 255, "pretty_title" => 255 }
#     # }.each_pair { |table, entries|
#     #   entries.each_pair { |col, sz|
#     #     query = "ALTER TABLE #{table} MODIFY COLUMN #{col} varchar(#{sz});"
#     #     puts query
#     #     adapter.execute(query)
#     #   }
#     # }
#   end

#   down do
#   end
# end

# migration 2, :carbon_copies do
#   up do
#     Page.all.each { |p|
#       unless p.carbon_copy
#         p.carbon_copy = CarbonCopy.create({ content: p.content })
#         p.save
#         puts "Page #{p.title} now has a CC."
#       end
#     }
#   end

#   down do
#     CarbonCopy.destroy
#   end
# end

# migration 3, :patch_changes do
  # up do
    # Revision.all.each { |rv|
      # diff = Marshal.load(rv.blob)
      # changes = { :additions => 0, :deletions => 0 }
      # diff.each { |changeset|
        # changeset.each { |d|
          # d.action == '-' ? changes[:deletions] += 1 : changes[:additions] += 1
        # }
      # }
      # rv.update!(changes.merge({ patchsz: rv.blob.length }))
      # puts "Updating revision #{rv.version}"
    # }
  # end
# 
  # down do
    # Revision.update({ additions: 0, deletions: 0, patchsz: 0 })
  # end
# end
# migration 3, :rename_pretty_to_publishing_settings do
#   up do
#     class Preferences; include PageHub::Helpers; end

#     User.each { |u|
#       prefs = Preferences.new.preferences(u)
#       if prefs["pretty"]
#         prefs["publishing"] = prefs.delete("pretty")
#         u.settings = prefs.to_json.to_s
#         unless u.save
#           puts "Error: unable to save the user #{u.nickname}, cause: #{u.collect_errors}"
#           break
#         end
#         puts "Updated user #{u.nickname}: #{prefs["publishing"]}"
#       end
#     }
#   end

#   down do
#     class Preferences; include PageHub::Helpers; end

#     User.each { |u|
#       prefs = Preferences.new.preferences(u)
#       if prefs["publishing"]
#         prefs["pretty"] = prefs.delete("publishing")
#         u.settings = prefs.to_json.to_s
#         unless u.save
#           puts "Error: unable to save the user #{u.nickname}, cause: #{u.collect_errors}"
#           break
#         end
#         puts "Updated user #{u.nickname}: #{prefs["pretty"]}"
#       end
#     }    
#   end
# end