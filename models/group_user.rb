class GroupUser
  include DataMapper::Resource

  belongs_to :group, key: true
  belongs_to :user, key: true

  property :is_admin, Boolean, default: false
end