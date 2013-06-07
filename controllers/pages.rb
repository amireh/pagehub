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

get '/spaces/:space_id/pages/:page_id',
  auth:     [ :user ],
  provides: [ :json ],
  requires: [ :space, :page ] do

  authorize! :read, @page, :message => "You need to be a member of this space to browse its pages."

  respond_with @page do |f|
    f.json { rabl :"pages/show" }
  end
end

get '/spaces/:space_id/pages/:page_id/edit',
  auth:     [ :user ],
  provides: [ :html ],
  requires: [ :space, :page ] do

  authorize! :author, @space, :message => "You need to be an editor of this space to edit pages."

  respond_to do |f|
    f.html {
      options = {}
      options[:layout] = false if request.xhr?
      erb :"/pages/new", options
    }
  end
end

post '/spaces/:space_id/pages',
  auth:     [ :editor ],
  provides: [ :json ],
  requires: [ :space ] do

  authorize! :author, @space, :message => "You need to be an editor of this space to create pages."
  authorize! :author_more, @space, :message => "You can not create any more pages in this space."

  api_required!({
    :folder_id  => lambda { |fid|
      "No such folder" unless @folder = @space.folders.get(fid)
    }
  })

  api_optional!({
    :title   => nil,
    :content => nil
  })

  @page = @space.pages.new api_params({
    creator: current_user,
    folder:  @folder
  })

  unless @page.save
    halt 400, @page.errors
  end

  respond_with @page do |f|
    f.json { rabl :"/pages/show" }
  end
end

put '/spaces/:space_id/pages/:page_id',
  auth:     [ :editor ],
  provides: [ :json ],
  requires: [ :space, :page ] do

  authorize! :author, @space, :message => "You need to be an editor of this space to edit pages."

  api_optional!({
    :title      => nil,
    :content    => nil,
    :browsable  => nil,
    :folder_id  => lambda { |fid|
      "No such folder" unless @folder = @space.folders.get(fid)
    }
  })

  if @api[:optional][:content]
    PageHub::Markdown::mutate! @api[:optional][:content]

    begin
      unless @page.generate_revision(@api[:optional][:content], current_user)
        halt 500, @page.collect_errors
      end
    rescue Page::Revision::NothingChangedError
      # it's ok
    rescue Page::Revision::PatchTooBigError
      # it's fine, too
      # TODO: push a warning msg
    end

    @page = @page.refresh
  end

  begin
    unless @page.update(api_params)
      halt 400, @page.errors
    end
  rescue DataObjects::DataError => e
    halt 400, "We were unable to save the page as its content is too long."
  end

  halt 200, {}.to_json if params[:no_object]

  respond_with @page do |f|
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
    f.json { halt 200, {}.to_json }
  end
end

# Version control
get '/pages/:page_id/revisions',
  auth: [ :user ],
  provides: [ :html ],
  requires: [ :page ] do

  authorize! :read, @page, message: "You need to be a member of this space to browse its page revisions."

  respond_with @page do |f|
    f.html do
      erb :"pages/revisions/index"
    end
  end
end

get '/pages/:page_id/revisions/:revision_id',
  auth: [ :user ],
  provides: [ :html ],
  requires: [ :page, :revision ] do

  authorize! :read, @page, message: "You need to be a member of this space to browse its page revisions."

  @rv = @revision

  @prev_rv = @rv.prev
  @next_rv = @rv.next

  respond_with @revision do |f|
    f.html { erb :"pages/revisions/show" }
  end
end

post '/pages/:page_id/revisions/:revision_id',
  auth: [ :user ],
  provides: [ :html ],
  requires: [ :page, :revision ] do

  authorize! :author, @page.space, message: "You can not perform this action."

  @space = @page.space

  @rv = @revision

  if !params[:confirmed] || params[:confirmed] != "do it"
    flash[:error] = "Will not roll-back until you have confirmed your action."
    return redirect @rv.url
  end

  unless @page.rollback(@rv)
    flash[:error] = "Page failed to rollback: #{@page.collect_errors}"
    return redirect @rv.url
  end

  flash[:notice] = "Page #{@page.title} has been restored to revision #{@rv.version}"

  redirect @rv.url
end
