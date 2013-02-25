object @user

attributes :id, :nickname, :email

node(:media) do |u|
  {
    href:   u.href,
    url:    u.url,
    spaces: {
      url:  u.url(true) + '/spaces'
    }
  }
end

node(:nr_pages) do |u| u.pages.count end
node(:nr_folders) do |u| u.folders.count end
  
node(:spaces) do
  partial "/spaces/index", object: @user.spaces
end
