class GroupUser
  include DataMapper::Resource

  belongs_to :group, key: true
  belongs_to :user, key: true

  property :role, Enum[:member, :editor, :admin], default: :member
end