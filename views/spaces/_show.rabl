object @space

attributes :id, :title, :brief, :is_public

node(:media) do |s|
  {
    href:   s.href,
    url:    s.url,
    pages:  {
      url: s.url(true) + '/pages'
    },
    folders: {
      url: s.url(true) + '/folders'
    }
  }
end

child(:creator => :creator) do |s|
  attributes :id
end
