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


def locate_folder(path, scope = nil, args = {})
  scope ||= @scope
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
    @page = @group.pages.first({ pretty_title: title })
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
post '/spaces/:space_id/pages',
  auth:     [ :editor ],
  provides: [ :json ],
  requires: [ :space ] do
  
  authorize! :create, Page, :message => "You need to be an editor in this space to create pages."
  
  api_required!({
    :title      => nil,
    :folder_id  => lambda { |fid|
      "No such folder" unless @folder = @space.folders.get(fid)
    }
  })
  
  api_optional!({
    :content => nil    
  })
  
  @page = @space.pages.new api_params({
    creator: @user,
    folder: @folder
  })
  
  unless @page.save
    halt 400, @page.errors
  end
  
  respond_with @page do |f|
    f.json { rabl :"/pages/show" }
  end
end
# post '/groups/:gid/pages', auth: :group_editor do |gid| create_page end

get '/spaces/:space_id/pages/:page_id',
  auth:     [ :user ],
  provides: [ :json ],
  requires: [ :space, :page ] do
    
  authorize! :read, @page, :message => "You need to be a member of this space to browse its pages."
  
  respond_with @page do |f|
    f.json { rabl :"pages/show" }
  end
end

put '/spaces/:space_id/pages/:page_id',
  auth:     [ :editor ],
  provides: [ :json, :html ],
  requires: [ :space, :page ] do

  authorize! :update, @page, :message => "You need to be an editor in this space to edit pages."
    
  api_optional!({
    :title      => nil,
    :content    => nil,
    :folder_id  => nil,
    :browsable  => nil
  })
  
  if @api[:optional][:content]
    PageHub::Markdown::mutate! @api[:optional][:content]

    begin
      unless @page.generate_revision(@api[:optional][:content], current_user)
        halt 500, @page.collect_errors
      end
    rescue Revision::NothingChangedError
      # it's ok
    end
  end

  unless @page.update(api_params)
    halt 400, @page.errors
  end

  respond_with @page do |f|
    f.html { erb :"pages/show" }
    f.json { rabl :"pages/show" }
  end
end

delete '/spaces/:space_id/pages/:page_id',
  auth:     [ :editor ],
  provides: [ :json, :html ],
  requires: [ :space, :page ] do
  
  authorize! :delete, @page, :message => "You can not remove pages authored by someone else."
  
  unless @page.destroy
    halt 500, @page.errors
  end
  
  respond_to do |f|
    f.html {
      flash[:notice] = "Page has been removed."
      redirect back
    }
    f.json { halt 200 }
  end
end

# delete '/groups/:gid/pages/:id', auth: :group_editor do |gid, id| delete_page(id) end

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

get '/:gname' do |gname|
  pass if reserved?(gname)
  
  unless @scope = @group = Group.first({name: gname })
    pass # it isn't a group, nevermind
  end

  if !@group.is_public && (!current_user || !@group.is_member?(current_user))
    halt 403, "You are not authorized to view this group's pages."
  end

  @page = @group.home_page

  return erb :"pages/pretty", layout: :"layouts/print"
end

# A group page. Group pages are visible to all members.
#
# Note: the reason we don't authenticate normally using
# the :auth scope is because we don't want to halt if
# the person isn't a member, instead we will pass into
# the anonymous capturer below this one.
get '/:gname/*' do |gname, crammed_path|
  pass if reserved?(gname) || !group_member?

  unless @scope = @group = Group.first({name: gname })
    halt 404, "No such group #{gname}."
  end

  possible_folder_title = crammed_path.split('/').last
  if @folder = @group.folders({pretty_title: possible_folder_title}).first
    return erb :"folders/pretty", layout: :"layouts/print"
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
  pass if reserved?(gname)
  unless @scope = @group = Group.first({name: gname })
    halt 404, "No such group #{gname}."
  end

  possible_folder_title = crammed_path.split('/').last
  if @folder = @group.folders({pretty_title: possible_folder_title}).first
    return erb :"folders/pretty", layout: :"layouts/print"
  end

  unless @page = locate_group_page(crammed_path)
    halt 404, "No such resource for the group #{@group.title} could be found."
  end

  if @group.is_public || @group.public_pages.first({ page: @page })
    @public = true
    return erb :"pages/pretty", layout: :"layouts/print"
  end

  halt 403, "That page is only viewable by its group members."
end