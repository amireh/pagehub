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

  [ :creator, :admin, :editor, :member ].each { |role|
    define_method "group_#{role}!" do |params|
      if g = locate_group(params)
        # puts "Checking if #{current_user.nickname} is a #{role} of the group #{g.name}"
        halt 403, "You are not an #{role} of this group." unless g.send("has_#{role}?".to_sym, current_user)
      else
        halt 400, "No such group."
      end

      puts "User #{current_user.nickname} is a #{role} of the group #{g.name}."
      g
    end
  }
  # def group_admin!(params)
  #   if g = locate_group(params)
  #     halt 403, "You are not an administrator of this group." unless g.has_editor?(current_user)
  #   else
  #     halt 400, "No such group."
  #   end
  #   g
  # end

  # def group_editor!(params)
  #   if g = locate_group(params)
  #     halt 403, "You are not an editor of this group." unless g.has_editor?(current_user)
  #   else
  #     halt 400, "No such group."
  #   end
  #   g
  # end
  
  # def group_member!(params)
  #   if g = locate_group(params)
  #     halt 403, "You are not a member of this group." unless g.has_member?(current_user)
  #   else
  #     halt 404, "No such group."
  #   end
  #   g
  # end

  set(:auth) do |*roles|
    condition do
      # in all cases, the user must be logged in
      restricted!

      # puts "Params in :auth => #{params.inspect}"
      # puts "Roles in :auth => #{roles.inspect}"

      if roles.include?(:group_creator)
        @group = group_creator! params
      elsif roles.include?(:group_admin)
        @group = group_admin! params
      elsif roles.include?(:group_member)
        @group = group_member! params
      elsif roles.include?(:group_editor)
        @group = group_editor! params
      elsif roles.include?(:user)
      end
    end
  end

  private

  def locate_group(params)
    puts params.inspect
    if params[:gid]
      return Group.first({ id: params[:gid] })
    elsif params[:current_name]
      return Group.first({ name: params[:current_name] })
    elsif params[:name] || params[:gname]
      return Group.first({ name: params[:name] || params[:gname] })
    else
      puts "ERROR: Can't find parameter to locate group with from #{params.inspect}"
    end
    nil
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
    if !current_user
      return settings.default_preferences
    end
    
    @preferences ||= JSON.parse(current_user.settings || "{}")
    defaults = settings.default_preferences.dup
    defaults.deep_merge(@preferences)
    # set_defaults(settings.default_preferences, @preferences)
  end
end