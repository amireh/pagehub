object @folder

attributes :id, :title

node :media do |f|
  partial("shared/media", object: f)
end