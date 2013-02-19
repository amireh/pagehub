class SpaceUser
  include DataMapper::Resource

  Roles = Enum[:member, :editor, :admin, :creator]
  Flags = Roles.flags
  
  class << self
    def weigh(role)
      Flags.index(role.to_sym) || -1
    end
    
    alias_method :weight_of, :weigh
  end
  
  belongs_to :space,  key: true
  belongs_to :user,   key: true

  property :role, Roles, default: :member
end