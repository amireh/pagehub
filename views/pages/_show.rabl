object @page

attributes :id, :title

node(:nr_revisions) do |p|
  p.revisions.count
end

node(:media) do |p|
  partial("shared/media", object: p)
end