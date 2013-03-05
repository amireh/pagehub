object @folder

attributes :id, :title, :pretty_title, :browsable

node :media do |f|
  {
    url:  f.url,
    href: f.href
  }
end

child(:folder => :parent) do |parent|
  attributes :id
end