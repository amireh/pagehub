object @user

attributes :id, :name, :nickname

node(:media) do |u|
  {
    href:   u.href
  }
end

node(:nr_pages) do |u| u.pages.count end
node(:nr_folders) do |u| u.folders.count end

node(:spaces) do
  puts @user.public_spaces(current_user).inspect
  partial "/spaces/index", object: @user.public_spaces(current_user)
end

node(:preferences) do |s|
  s.preferences
end