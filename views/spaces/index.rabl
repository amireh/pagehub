collection @user.spaces, :root => "spaces", :object_root => false

extends "spaces/_show"

node(:role) do |s| s.role_of(@user) end
node(:nr_pages) do |s| s.pages.count end
node(:nr_folders) do |s| s.folders.count end
node(:nr_members) do |s| s.users.count end