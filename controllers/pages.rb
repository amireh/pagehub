get '/pages/:id.json' do |id|
  restricted!

  unless p = Page.first(id: id, user: current_user)
    halt 404, "Page ##{id} does not exist."
  end

  p.serialize.merge({ content: p.content }).to_json
end

get '/groups/:gid/pages/:id.json', auth: :group_member do |gid, id|
  unless p = @group.pages.first(id: id)
    halt 404, "Page ##{id} does not exist."
  end

  p.serialize.merge({ content: p.content }).to_json
end

put '/pages/:id' do |id|
  restricted!

  unless p = Page.first({ id: id, user_id: current_user.id })
    halt 501, "No such page: #{id}!"
  end

  p.update(params[:attributes])
  p.to_json
end

put '/groups/:gid/pages/:id', :auth => :group_editor do |gid, id|
  # restricted!
  # g = group_editor! gid

  unless p = Page.first({ id: id, group: @group })
    halt 501, "No such page: #{id}!"
  end

  p.update(params[:attributes])
  p.to_json  
end

# Creates a blank new page
post '/pages' do
  restricted!

  Page.create({ user_id: current_user.id }).to_json
end

post '/groups/:gid/pages', auth: :group_editor do |gid|
  Page.create({ user: current_user, group: @group }).to_json
end

delete '/pages/:id' do |id|
  restricted!

  p = Page.first({ id: id, user_id: current_user.id })
  
  halt 400, "No such page" if !p

  p.destroy

  true.to_json
end

delete '/groups/:gid/pages/:id' do |gid, id|
  restricted!

  # only the author can remove their own posts

  unless p = Page.first({ id: id })
    halt 404, "No such page #{id}."
  end

  unless p.deletable_by? current_user
    halt 403, "Only the author may delete their pages."
  end

  p.destroy
  true.to_json
end

get '/pages/public' do
  restricted!

  @pages = []
  PublicPage.all({ user_id: current_user.id }).each { |pp|
    p = Page.first({ id: pp.page_id, user_id: pp.user_id })
    if p then @pages << p end
  }

  erb :"pages/public"
end


get '/pages/:id/pretty' do |id|
  restricted!

  @page = Page.first({ id: id, user_id: current_user.id })

  halt 501, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  erb :"pages/pretty", layout: :"layouts/print"
end


# Creates a publicly accessible version of the given page.
# The public version will be accessible at:
# => /user-nickname/pretty-article-title
#
# See String.sanitize for the nickname and pretty page titles.
get '/pages/:id/share' do |id|
  restricted!

  @page = Page.first({ id: id, user_id: current_user.id })

  halt 404, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  @pp = PublicPage.first_or_create({ page_id: @page.id, user_id: @page.user_id })

  redirect "/#{@page.user.nickname}/#{@page.title.sanitize}"
end

get '/pages/:id/share/:group' do |id, group_name|
  restricted!

  unless g = Group.first(name: group_name)
    halt 400, "There's no group named #{group_name}."
  end

  halt 403, "You do not belong to that group" unless g.has_member?(current_user)

  @page = Page.first({ id: id, user_id: current_user.id })

  halt 404, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  unless g.has_page?(@page)
    g.pages << @page
    g.save
  end

  redirect "/#{g.name}/#{@page.title.sanitize}"
end

# Removes the public status of a page, it will no longer
# be viewable by others.
get '/pages/:id/unshare' do |id|
  restricted!

  @page = Page.first({ id: id, user_id: current_user.id })

  halt 501, "This link seems to point to a non-existent page, you sure you got it right?" if !@page

  @pp = PublicPage.first({ page_id: @page.id, user_id: @page.user_id })
  if @pp then
    @pp.destroy
    flash[:notice] = "The page titled #{@page.title} is no longer publicly shared."
  else
    flash[:error] = "This page does not seem to be publicly shared, are you sure you've shared it?"
  end

  redirect :"/pages/public"
end

# Removes the public status of a page, it will no longer
# be viewable by others.
get '/pages/:id/unshare/:group_id' do |id, group_id|
  restricted!

  gp = GroupPage.first({ page_id: id, group_id: group_id })

  halt 501, "That page doesn't seem to be shared with that group." if !gp

  page = Page.get(gp.page_id)
  group = Group.first({ id: gp.group_id })

  gp.destroy

  flash[:notice] = "Page #{page.title} is no longer shared with the group #{group.title}."
  redirect :"/pages/public"
end


# Retrieve a publicly accessible page.
get '/:nickname/:title' do |nn, title|
  # try a public-shared page
  @user = User.first({ nickname: nn })
  if @user
    unless @page = Page.first({ pretty_title: title.sanitize, user_id: @user.id })
      puts "ERROR: public page could not be found with sane title: #{title.sanitize}"

      halt 404, "No page with title #{title} could be found."
    end

    @pp = PublicPage.first({ page_id: @page.id, user_id: @user.id })
    halt 403, "This page can only be viewed by its author." if !@pp

    @public = true
    return erb :"pages/pretty", layout: :"layouts/print"
  end

  # try a group shared page    
  if @group = Group.first({ name: nn })
    if current_user
      # the user must belong to this group
      if !@group.has_member?(current_user)
        halt 403, "You do not have access to the pages of this group."
      end

      # locate the page
      pages = Page.all({ pretty_title: title.sanitize })
      pages.each { |p| 
        group_page = GroupPage.first({ group_id: @group.id, page_id: p.id })
        if group_page
          @page = p
          break
        end
      }

      if @page then
        @public = true
        return erb :"pages/pretty", layout: :"layouts/print"
      end

      halt 404, "No page with title #{title} for the group #{nn} could be found."
    else
      # not logged in
      halt 403, "You must be logged in as a member of the group #{@group.title} to view this page."
    end
  end

  halt 404, "This seems to be an invalid link."
end