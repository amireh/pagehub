ability do |user, space|
  user ||= User.new

  can :browse, [ Space, Page, Folder ] do |r|
    r.browsable_by?(user)
  end

  return false unless user.saved?

  can :read, [ Space, Page, Folder ] do |r|
    # puts "checking if #{user.email} with role #{p.space.role_of(user)} can [read]"
    r.browsable_by?(user)
  end

  # spaces
  can :create, Space

  if space
    if space.editor?(user)
      can :create, [ Page, Folder ]
      can :update, [ Page, Folder ]
      can :delete, [ Page, Folder ] do |r|
        # puts "checking if #{user.email} with role #{r.space.role_of(user)} #{r.creator.id == user.id} can [delete]"
        r.creator.id == user.id || r.space.admin?(user)
      end

    end

    if space.admin?(user)
      # puts "checking admin permissions"
      can :update, Space

      can :invite, Array do |a|
        target, role = *a
        # puts "checking if #{space.role_of(user)}##{user.id} can invite #{target.id} as #{role}"
        space.role_of(target) == nil && role.to_sym != :admin
      end

      can :kick, User do |target|
        # puts "checking if #{space.role_of(user)}##{user.id} can kick #{space.role_of(target)}##{target.id}"
        !space.admin?(target)
      end

      can :promote, Array do |a|
        target, role = *a

        # puts "checking if #{space.role_of(user)}##{user.id} can promote #{space.role_of(target)}##{target.id} into #{role}"
        space.member?(target) && [:member, :editor].include?(role.to_sym)
      end

      can :demote, Array do |a|
        target, role = *a

        # puts "checking if #{space.role_of(user)}##{user.id} can demote #{space.role_of(target)}##{target.id} into #{role}"
        !space.admin?(target) && [:member, :editor].include?(role.to_sym)
      end

    end

    if space.creator?(user)
      can :update_meta, Space
      can :delete,      Space
      can :invite,      Array
      can :kick,        User
      can :promote,     Array
      can :demote,      Array
    end
  end
end