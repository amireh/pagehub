object @page

attributes :id, :title, :pretty_title, :folder_id, :browsable

node(:media) do |p|
  partial "pages/_media", object: p
end