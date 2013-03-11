object @user

attributes :id, :name, :nickname

node(:media) do |u|
  {
    href:   u.href,
    url:    u.url,
    spaces: {
      url:  u.url(true) + '/spaces'
    },
  }
end
