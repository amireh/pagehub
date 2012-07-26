get '/pages/:id.json' do |id|
  halt 401 unless logged_in?

  p = Page.first(id: id, user_id: current_user.id)

  if !p
    return "Sorry, I was unable to find the page :("
  end

  p.content
end

put '/pages/:id' do |id|
  halt 401 unless logged_in?

  p = Page.first({ id: id, user_id: current_user.id })
  
  halt 501, "No such page: #{id}!".to_json if !p

  p.update(params[:attributes])

  true.to_json
end

get '/pages/:id/preview' do |id|
  halt 401 unless logged_in?

  # @page = Page.first_or_create({ pretty_title: title.sanitize, user_id: current_user.id },
  # { title: title })
  @page = Page.first({ id: id, user_id: current_user.id })

  halt 501, "This link seems to point to a non-existent page, you sure you got it right?" if !@page
  # if page.saved?
  #   return page.content.to_markdown
  # else
  #   return "Sorry, I was unable to find the page :("
  # end
  erb :"preview", layout: :"print_layout"
end

get '/pages/:id/share' do |id|
  halt 401 unless logged_in?

  # @page = Page.first_or_create({ pretty_title: title.sanitize, user_id: current_user.id },
  # { title: title })
  @page = Page.first({ id: id, user_id: current_user.id })

  halt 501, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  @pp = PublicPage.create({ page_id: @page.id, user_id: @page.user_id })

  redirect "/#{@page.user.nickname}/#{@page.title.sanitize}"

  # if page.saved?
  #   return page.content.to_markdown
  # else
  #   return "Sorry, I was unable to find the page :("
  # end
  # erb :"preview", layout: :"print_layout"
end

post '/pages' do
  halt 401 unless logged_in?

  Page.create({ user_id: current_user.id }).id.to_json
end

delete '/pages/:id' do |id|
  halt 401 unless logged_in?

  p = Page.first({ id: id, user_id: current_user.id })
  
  halt 400, "No such page" if !p

  p.destroy

  true.to_json
end

get '/:nickname/:title' do |nn, title|
  user = User.first({ nickname: nn })
  halt 404, "This seems to be an invalid link, sorry :(" if !user
  @page = Page.first({ pretty_title: title, user_id: user.id })
  halt 404, "This seems to be an invalid link, sorry :(" if !user

  erb :"preview", layout: :"print_layout"
end