get '/pages/:id.json' do |id|
  restricted!

  p = Page.first(id: id, user_id: current_user.id)

  if !p
    return "Sorry, I was unable to find the page :("
  end

  p.content
end

put '/pages/:id' do |id|
  restricted!

  p = Page.first({ id: id, user_id: current_user.id })
  
  halt 501, "No such page: #{id}!".to_json if !p

  p.update(params[:attributes])

  true.to_json
end

get '/pages/:id/pretty' do |id|
  restricted!

  @page = Page.first({ id: id, user_id: current_user.id })

  halt 501, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  erb :"pretty", layout: :"print_layout"
end

# Creates a blank new page
post '/pages' do
  restricted!

  Page.create({ user_id: current_user.id }).id.to_json
end

delete '/pages/:id' do |id|
  restricted!

  p = Page.first({ id: id, user_id: current_user.id })
  
  halt 400, "No such page" if !p

  p.destroy

  true.to_json
end

# Creates a publicly accessible version of the given page.
# The public version will be accessible at:
# => /user-nickname/pretty-article-title
#
# See String.sanitize for the nickname and pretty page titles.
get '/pages/:id/share' do |id|
  restricted!

  @page = Page.first({ id: id, user_id: current_user.id })

  halt 501, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  @pp = PublicPage.first_or_create({ page_id: @page.id, user_id: @page.user_id })

  redirect "/#{@page.user.nickname}/#{@page.title.sanitize}"
end

# Retrieve a publicly accessible page.
get '/:nickname/:title.raw' do |nn, title|
  @user = User.first({ nickname: nn })
  halt 404, "This seems to be an invalid link, sorry :(" if !@user
  @page = Page.first({ pretty_title: title, user_id: @user.id })
  halt 404, "This seems to be an invalid link, sorry :(" if !@page
  @public = true
  @page.content
end
# Retrieve a publicly accessible page.
get '/:nickname/:title' do |nn, title|
  @user = User.first({ nickname: nn })
  halt 404, "This seems to be an invalid link, sorry :(" if !@user
  @page = Page.first({ pretty_title: title, user_id: @user.id })
  halt 404, "This seems to be an invalid link, sorry :(" if !@page
  @public = true
  erb :"pretty", layout: :"print_layout"
end