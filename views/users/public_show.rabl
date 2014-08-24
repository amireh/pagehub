object @user

attributes :id, :name, :nickname

node(:media) do |u|
  {
    href:   u.href,
    spaces: {
      url:  u.url(true) + '/spaces'
    }
  }
end

node(:nr_pages) do |u| u.pages.count end
node(:nr_folders) do |u| u.folders.count end

node(:spaces) do
  partial "/spaces/index", object: @user.public_spaces(current_user)
end

node(:preferences) do |s|
  s.preferences
end