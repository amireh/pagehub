object @space

extends "spaces/_show"

node(:root_folder) do |s|
  partial "folders/_show", object: s.root_folder
end
node(:folders) do |s|
  s.folders.map { |f| partial "folders/_show_with_pages", object: f }
end