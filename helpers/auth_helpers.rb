module RoleInspector

  def logged_in?
    !current_user.nil?
  end

  def current_user
    return @user if @user
    return nil unless session[:id]

    @user = User.get(session[:id])
  end

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
        halt 403, "You are not #{vowelize(role)} of this group." unless g.send("has_#{role}?".to_sym, current_user)
      else
        halt 400, "No such group."
      end

      # puts "User #{current_user.nickname} is a #{role} of the group #{g.name}."
      g
    end

    define_method "group_#{role}?" do# do |params|
      if g = locate_group(params)
        return false unless g.send("has_#{role}?".to_sym, current_user)
      else
        halt 400, "No such group."
      end
      true
    end
  }

  set(:auth) do |*roles|
    condition do
      # in all cases, the user must be logged in
      restricted!

      @scope = current_user

      # puts "Params in :auth => #{params.inspect}"
      # puts "Roles in :auth => #{roles.inspect}"
      [ :creator, :admin, :member, :editor ].each { |role|
        if roles.include?("group_#{role}".to_sym)
          @scope = @group = send("group_#{role}!", params)
          break
        end
      }
      # if roles.include?(:group_creator)
      #   @scope = @group = group_creator! params
      # elsif roles.include?(:group_admin)
      #   @scope = @group = group_admin! params
      # elsif roles.include?(:group_member)
      #   @scope = @group = group_member! params
      # elsif roles.include?(:group_editor)
      #   @scope = @group = group_editor! params
      # elsif roles.include?(:user)
      # end
    end
  end

  private

  def locate_group(params)
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
end