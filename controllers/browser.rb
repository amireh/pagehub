get '/:user_nickname/:space_pretty_title/edit', auth: :user, :provides => [ :html ] do |user_nn, space_pt|
  unless u = User.first(nickname: user_nn.sanitize)
    pass
  end

  unless @space = u.spaces.first({ pretty_title: space_pt.sanitize })
    halt 404, "No such space #{space_pt} for user #{u.nickname}"
  end

  authorize! :access, @space, message: "You are not allowed to access that space."

  @user = current_user

  respond_with @space do |f|
    f.json { rabl :"/spaces/show", object: @space }
    f.html { erb :"/spaces/show" }
  end
end

get '/:user_nickname/:space_pretty_title/settings', auth: :user, :provides => [ :html ] do |user_nn, space_pt|
  unless u = User.first({ nickname: user_nn.sanitize })
    pass
  end

  unless @space = u.spaces.first({ pretty_title: space_pt.sanitize })
    halt 404, "No such space #{space_pt} for user #{u.nickname}"
  end

  authorize! :update, @space, message: "You must be an admin of this space to manage it."

  @user = current_user
  respond_with @space do |f|
    f.html { erb :"/spaces/settings/index" }
  end
end

get '/:user_nickname/:space_pretty_title*', :provides => [ :html ] do |user_nn, space_pt, path|
  unless u = User.first({ nickname: user_nn.sanitize })
    # halt 404, "No such user #{user_nn}."
    pass
  end

  unless s = u.spaces.first({ pretty_title: space_pt.sanitize })
    halt 404, "No such space #{space_pt} for user #{u.nickname}"
  end

  unless can? :browse, s
    halt 401, "You are not allowed to browse that space."
  end

  path = path.split('/')

  unless p = s.locate_resource(path)
    halt 404, "No such page #{path.last} in #{s.title}"
  end

  unless can? :browse, p
    halt 401, "You are not allowed to view that page."
  end

  @space  = s
  @page   = p
  @folder = @page.folder

  respond_to do |f|
    f.html { erb  :"pages/pretty", layout: :"layouts/print" }
    f.json { rabl :"pages/show", object: p }
  end
end

get '/:user_nickname', provides: [ :html ] do |user_nn|
  unless @user = User.first({ nickname: user_nn.sanitize })
    pass
  end

  respond_with @user do |f|
    f.html { erb :"users/dashboard" }
  end
end