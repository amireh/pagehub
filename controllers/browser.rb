def user_space(user, q)
  user.owned_spaces.first(q) || user.spaces.first(q)
end

def strip_trailing_slash!(str)
  str.gsub!(/\/$/, '')
end

get '/:user_nickname/:space_pretty_title/edit*', auth: :user, :provides => [ :html ] do |user_nn, space_pt, *_|
  unless u = User.first(nickname: user_nn.sanitize)
    pass
  end

  unless @space = user_space(u, { pretty_title: space_pt.sanitize })
    halt 404, "No such space #{space_pt} for user #{u.nickname}"
  end

  authorize! :access, @space, message: "You are not allowed to access that space."

  respond_with @space do |f|
    f.html { erb :"/spaces/show" }
  end
end

get '/:user_nickname/:space_pretty_title/settings', auth: :user, :provides => [ :html ] do |user_nn, space_pt|
  unless u = User.first({ nickname: user_nn.sanitize })
    pass
  end

  unless @space = user_space(u, { pretty_title: space_pt.sanitize })
    halt 404, "No such space #{space_pt} for user #{u.nickname}"
  end

  authorize! :update, @space, message: "You must be an admin of this space to manage it."

  @user = current_user

  respond_with @space do |f|
    f.html { erb :"/spaces/settings/index" }
  end
end

get %r{([^\/]{3,})\/([^\/]{3,})(\/.*)?$},
  :provides => [ :html, :json, :text ] do |user_nn, space_pt, path|

  cross_origin

  strip_trailing_slash! user_nn

  unless u = User.first({ nickname: user_nn.sanitize })
    # halt 404, "No such user #{user_nn}."
    pass
  end

  strip_trailing_slash! space_pt

  unless s = user_space(u, { pretty_title: space_pt.sanitize })
    halt 404, "No such space #{space_pt} for user #{u.nickname}"
  end

  unless can? :browse, s
    halt 401, "You are not allowed to browse that space."
  end

  p = nil
  ext = nil

  if path && !path.empty?
    strip_trailing_slash! path

    path = path.split('/').reject(&:empty?).map { |fragment| fragment.gsub(/\/$/, '') }

    if path.last =~ /\.[html|json|text]/
      path.last.gsub!(/\.(.+)/, '')
      ext = $1

      case ext
      when "html"; content_type :html; @content_only = true
      when "json"; content_type :json
      when "text"; content_type :text
      end
    end

    unless p = s.locate_resource(path)
      halt 404, "No such page #{path.last} in #{s.title}"
    end
  else
    p = s.homepage || s.pages.first
  end

  unless can? :browse, p
    halt 401, "You are not allowed to view that page."
  end

  @space  = s
  @page   = p
  @folder = @page.folder

  respond_to do |f|
    f.html {
      if @content_only
        md @page.content
      else
        erb :"pages/pretty", layout: :"layouts/print"
      end
    }
    f.json { rabl :"pages/show", object: p }
    f.text { p.content }
  end
end

get '/:user_nickname*', provides: [ :html ] do |user_nn, *garbage|
  unless @user = User.first({ nickname: user_nn.sanitize })
    pass
  end

  respond_with @user do |f|
    f.html { erb :"users/dashboard" }
  end
end