object @page

attributes :id, :title, :folder_id

node(:media) do |p|
  partial "pages/_media", object: p
end