module RoleInspector

  def restricted
    unless logged_in?
      flash[:error] = "You must sign in first."
      redirect "/", 303
    end
  end

  def restricted!(scope = nil)
    halt 401, "You must sign in first." unless logged_in?
  end

  def group_editor!(gid)
    if g = Group.first(id: gid)
      halt 403, "You are not an editor of this group." unless g.has_editor?(current_user)
    end

    halt 404, "No such group ##{gid}." unless g

    g
  end
  
  def group_member!(gid)
    if g = Group.first(id: gid)
      halt 403, "You are not a member of this group." unless g.has_member?(current_user)
    end

    halt 404, "No such group ##{gid}." unless g

    g
  end

  set(:auth) do |*roles|   # <- notice the splat here
    condition do
      # puts "Params in :auth => #{params.inspect}"
      # puts "Roles in :auth => #{roles.inspect}"

      if roles.include?(:group_editor)
        restricted!
        @group = group_editor! params[:gid]
      elsif roles.include?(:user)
        restricted!
      end
    end
  end

end

helpers do
  include RoleInspector

  def logged_in?
    session[:id]
  end

  def current_user
    return @user if @user
    return nil unless logged_in?

    @user = User.get(session[:id])
  end

  # Loads the user's preferences merging them with the defaults
  # for any that were not overridden.
  #
  # Side-effects:
  # => @preferences will be overridden with the current user's settings
  def preferences
    if not current_user then
      return settings.default_preferences
    end
    
    @preferences ||= JSON.parse(current_user.settings || "{}")
    defaults = settings.default_preferences.dup
    defaults.deep_merge(@preferences)
    # set_defaults(settings.default_preferences, @preferences)
  end
end