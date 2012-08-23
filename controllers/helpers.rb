def name_available?(name)
  nn = name.to_s.sanitize
  nn != 'name' && !name.empty? && User.first(nickname: nn).nil? && Group.first(name: nn).nil?
end