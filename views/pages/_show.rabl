object @page

attributes :id, :title, :pretty_title, :browsable

child(:folder => :folder) do |folder|
  attributes :id
end

node(:media) do |p|
  partial "pages/_media", object: p
end