object @space

attributes :id, :title, :brief, :is_public

node(:meta) do |s|
  {
    nr_pages:   s.pages.count,
    nr_folders: s.folders.count,
    nr_members: s.users.count
  }
end

node(:media) do |s|
  {
    href:   s.href,
    url:    s.url,

    actions: {
      edit: s.edit_url,
      settings: s.settings_url,
      name_availability: s.creator.url + '/spaces/name'
    },

    pages:  {
      url: s.url(true) + '/pages'
    },
    folders: {
      url: s.url(true) + '/folders'
    },
    name_availability_url: s.creator.url + '/spaces/name'
  }
end

child(:creator => :creator) do |u|
  # partial "/users/_show", object: u
  attributes :id
end
