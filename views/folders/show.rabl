object @folder

extends "folders/_show"

attributes :browsable

child(:space) do |space|
  partial "spaces/_show", object: space
end

node(:folders) { |f|
  f.folders.collect { |cf| partial "folders/_show", object: cf }
}

node(:pages) { |f|
  f.pages.collect { |p| partial "pages/_show", object: p }
}