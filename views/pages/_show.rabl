object @page

attributes :id, :title

node(:media) do |p|
  partial "pages/_media", object: p
end