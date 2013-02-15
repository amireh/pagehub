object @page

attributes :id, :title, :content

node(:nr_revisions) do |p|
  p.revisions.count
end

child :folder do
  attributes :id
end