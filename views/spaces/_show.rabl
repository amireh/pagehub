object @space

attributes :id, :title, :brief, :is_public

node(:meta) do |s|
  {
    nr_pages: s.pages.count,
    nr_folders: s.folders.count,
    nr_members: s.users.count
  }
end

node(:media) do |s|
  {
    href:   s.href,
    url:    s.url,
    pages:  {
      url: s.url(true) + '/pages'
    },
    folders: {
      url: s.url(true) + '/folders'
    },
    name_availability_url: s.creator.url + '/spaces/name'
  }
end

child(:creator => :creator) do |s|
  attributes :id
end
