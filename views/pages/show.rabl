object @page

extends "pages/_show"

attributes :content

node(:nr_revisions) do |p|
  p.revisions.count
end

child(:folder) do |f|
  partial "folders/_show", object: f
end

node(:media) do |p|
  partial "pages/_media", object: p
end