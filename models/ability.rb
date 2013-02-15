ability do |user, space|
  user ||= User.new
  
  can :read, [ Page, Folder ] do |r|
    # puts "checking if #{user.email} with role #{p.space.role_of(user)} can [read]"
    r.browsable? || r.space.member?(user)
  end
  
  can :create, [ Page, Folder ] if space && space.editor?(user)
  
  can :update, [ Page, Folder ] do |r|
    # puts "checking if #{user.email} with role #{p.space.role_of(user)} can [update|create]"
    r.space.editor?(user)
  end
    
  can :delete, [ Page, Folder ] do |r|
    # puts "checking if #{user.email} with role #{r.space.role_of(user)} #{r.creator.id == user.id} can [delete]"
    r.creator.id == user.id || r.space.admin?(user)
  end
  
  # spaces
  
  can :read, Space do |s|
    s.is_public || s.member?(user)
  end
  
  can :create, Space if user.saved?
  
  can :update, Space do |s|
    s.admin?(user)
  end
  
  can :delete, Space do |s|
    s.creator.id == user.id
  end
end