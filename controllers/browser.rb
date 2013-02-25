get '/:user_nickname/:space_pretty_title*', :provides => [ :html ] do |user_nn, space_pt, path|
  unless u = User.first(nickname: user_nn)
    # halt 404, "No such user #{user_nn}."
    pass
  end
  
  unless s = u.spaces.first({ pretty_title: space_pt })
    halt 404, "No such space #{space_pt} for user #{user.nickname}"
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
  
  @space = s
  @page = p
  
  respond_to do |f|
    f.html { erb  :"pages/pretty", layout: :"layouts/print" }
    f.json { rabl :"pages/show", object: p }
  end
end