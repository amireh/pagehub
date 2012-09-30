# @scope is identified in helpers/auth_helper.rb, it points to a user or a group

# Creates a blank new page
def create_page()
  p = @scope.pages.create({ user: current_user })
  p.to_json
end

def load_page(pid)
  unless p = @scope.pages.first(id: pid)
    halt 400, "Page ##{pid} does not exist."
  end

  p.serialize.merge({ content: p.content }).to_json
end

def update_page(pid)
  unless p = @scope.pages.first({ id: pid })
    halt 501, "No such page: #{pid}!"
  end

  force_content_update = false
  unless params[:attributes][:autosave]
    if params[:attributes][:content]
      force_content_update = PageHub::Markdown::mutate! params[:attributes][:content]
    end

    begin
      unless p.generate_revision(params[:attributes][:content], current_user)
        puts "Page failed to generate RV"
        halt 400, p.collect_errors
      end

      # p.save
    rescue Revision::NothingChangedError
      # it's ok, we'll just not store a revision
    end
  end

  if p.dirty?
    halt 500, "Something _really_ bad happened."
  end

  params[:attributes].delete("autosave")

  unless p.update(params[:attributes])
    halt 400, p.collect_errors
  end

  p.serialize(force_content_update).to_json
end

def delete_page(pid)
  unless p = @scope.pages.first({ id: pid })
    halt 400, "No such page."
  end

  p.operating_user = current_user

  if !p.destroy
    halt 500, p.collect_errors
  end

  true
end

def pretty_view(pid)
  unless @page = @scope.pages.first({ id: pid })
    halt 500, "This link seems to point to a non-existent page."
  end

  erb :"pages/pretty", layout: :"layouts/print"
end

# Creates a publicly accessible version of the given page.
# The public version will be accessible at:
# => /user-nickname/pretty-article-title
#
# See String.sanitize for the nickname and pretty page titles.
def share_page(id)
  unless @page = @scope.pages.first({ id: id })
    halt 404, "This link seems to point to a non-existent page."
  end

  unless pp = @scope.public_pages.first({ page: @page })
    pp = @scope.public_pages.create({ page: @page, user: current_user })
  end

  redirect pp.url
end


def unshare_page(pid)
  unless page = @scope.pages.first({ id: pid })
    halt 400, "No such page."
  end

  unless pp = @scope.public_pages.first({ page: page })
    halt 400, "That page isn't shared."
  end

  if pp.destroy
    flash[:notice] = "Page #{page.title} is no longer shared with the public."
  else
    flash[:error] = "Unable to un-share the page, please try again."
  end

  redirect back
end


def locate_folder(path, scope, args = {})
  fidx = 0
  f = nil
  while fidx < path.length - 1
    unless f = scope.folders.first({ pretty_title: path[fidx] }.merge(args))
      break
    end

    fidx += 1
  end
  f
end

def locate_group_page(crammed_path)
  path = crammed_path.split('/')

  puts "looking for a group page"

  if path.length > 1
    unless f = locate_folder(path, @group, {})
      halt 404
    end

    puts f.inspect

    unless @page = f.pages.first({ pretty_title: path.last })
      halt 404
    end
  else
    title = crammed_path.sanitize

    # locate the page
    @page = @group.page.first({ pretty_title: title })
  end

  @page
end

def load_revisions(pid)
  unless @page = @scope.pages.first({ id: pid })
    halt 404, "No such page."
  end

  erb "/pages/revisions/index".to_sym
end

def load_revision(pid, rid)
  unless @page = @scope.pages.first({ id: pid })
    halt 404, "No such page."
  end

  unless @rv = @page.revisions.first({ id: rid })
    halt 404, "No such revision."
  end

  @prev_rv = @rv.prev
  @next_rv = @rv.next

  erb "/pages/revisions/show".to_sym
end

def rollback_page(pid, rid)
  unless @page = @scope.pages.first({ id: pid })
    halt 404, "No such page."
  end
  unless @rv = @page.revisions.first({ id: rid })
    halt 404, "No such revision."
  end

  if !params[:confirmed] || params[:confirmed] != "do it"
    flash[:error] = "Will not roll-back until you have confirmed your action."
    return redirect @rv.url(@scope.namespace)
  end

  unless @page.rollback(@rv)
    flash[:error] = "Page failed to rollback: #{@page.collect_errors}"
    return redirect @rv.url(@scope.namespace)
  end

  flash[:notice] = "Page #{@page.title} has been restored to revision #{@rv.version}"

  redirect @rv.url(@scope.namespace)
end

# CRUDs
post '/pages', auth: :user do create_page end
post '/groups/:gid/pages', auth: :group_editor do |gid| create_page end

get '/pages/:id.json', auth: :user do |id| load_page(id) end
get '/groups/:gid/pages/:id.json', auth: :group_member do |gid, id| load_page(id) end

put '/pages/:id', auth: :user do |id| update_page(id) end
put '/groups/:gid/pages/:id', :auth => :group_editor do |gid, id| update_page(id) end

delete '/pages/:id', auth: :user do |id| delete_page(id) end
delete '/groups/:gid/pages/:id', auth: :group_editor do |gid, id| delete_page(id) end

# Version control
get '/pages/:id/revisions', auth: :user do |pid| load_revisions(pid) end
get '/groups/:gid/pages/:id/revisions', auth: :group_editor do |gid, pid| load_revisions(pid) end

get '/pages/:id/revisions/:rid', auth: :user do |pid, rid| load_revision(pid, rid) end
get '/groups/:gid/pages/:id/revisions/:rid', auth: :group_editor do |gid, pid, rid| load_revision(pid, rid) end

post '/pages/:id/revisions/:rid', auth: :user do |pid, rid| rollback_page(pid, rid) end
post '/groups/:gid/pages/:id/revisions/:rid', auth: :group_editor do |gid, pid, rid| rollback_page(pid, rid) end

# get '/pages/public', auth: :user do
#   nr_invalidated_links = 0

#   @pages = []
#   @scope.public_pages.all.each { |pp|
#     p = @scope.pages.first({ id: pp.page_id })

#     if p then
#       @pages << p
#     else
#       nr_invalidated_links += 1
#       pp.destroy
#     end

#   }

#   if nr_invalidated_links > 0
#     flash[:notice] =
#       "#{nr_invalidated_links} public links have been invalidated because \
#       the pages they point to have deleted."
#   end

#   erb :"pages/public"
# end

get '/pages/:id/pretty', auth: :user do |id| pretty_view(id) end
get '/groups/:gid/pages/:id/pretty', auth: :group_member do |gid, id| pretty_view(id) end

get '/pages/:id/share', auth: [ :user ] do |id| share_page(id) end
get '/groups/:gid/pages/:id/share', auth: [ :group_editor ] do |gid, pid| share_page(pid) end

# Removes the public status of a page, it will no longer
# be viewable by others.
get '/pages/:id/unshare', auth: [ :user ] do |id|
  unshare_page(id)
end

# Removes the public status of a page, it will no longer
# be viewable by others.
get '/groups/:gid/pages/:id/unshare', auth: [ :group_editor ] do |gid, pid|
  unshare_page(pid)
end

# Retrieve a publicly shared user page.
get '/:nickname/*' do |nn, crammed_path|
  path = crammed_path.split('/')

  # try a user shared page
  user = User.first({ nickname: nn })
  if !user
    pass
  end

  if path.length > 1
    unless f = locate_folder(path, user, { group: nil })
      halt 404
    end

    unless @page = f.pages.first({ pretty_title: path.last })
      halt 404
    end
  else
    title = crammed_path.sanitize
    unless @page = user.pages.first({ pretty_title: title })
      # puts "ERROR: public page could not be found with sane title: #{title.sanitize}"
      halt 404#, "No page with title #{title} could be found."
    end
  end

  # is it shared?
  unless user == current_user || user.public_pages.first({ page: @page })
    halt 403, "This page can only be viewed by its author."
  end

  @public = true
  return erb :"pages/pretty", layout: :"layouts/print"
end

# A group page. Group pages are visible to all members.
#
# Note: the reason we don't authenticate normally using
# the :auth scope is because we don't want to halt if
# the person isn't a member, instead we will pass into
# the anonymous capturer below this one.
get '/:gname/*' do |gname, crammed_path|
  pass if !group_member?

  unless @scope = @group = Group.first({name: gname })
    halt 404, "No such group."
  end

  @page = locate_group_page(crammed_path)

  if !@page
    halt 404, "No such page."
  end

  @public = true
  erb :"pages/pretty", layout: :"layouts/print"
end

# A group shared page
get '/:gname/*' do |gname, crammed_path|
  unless @scope = @group = Group.first({name: gname })
    halt 404, "No such group."
  end

  unless @page = locate_group_page(crammed_path)
    halt 404, "No page with title for the group #{@group.title} could be found."
  end

  if !@group.public_pages.first({ page: @page })
    halt 403, "That page is only viewable by its group members."
  end

  @public = true
  erb :"pages/pretty", layout: :"layouts/print"
end