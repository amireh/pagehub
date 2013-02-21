object @folder

extends "folders/_show"

node(:pages) do |f|
  f.pages.collect { |p| partial "pages/_show", object: p }
end