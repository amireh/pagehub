class Group
  include DataMapper::Resource
  
  Roles = [ :member, :editor, :admin ]
  
  property :id, Serial
  property :name,       String, length: 120, unique: true, required: true
  property :title,      String, length: 120
  property :is_public,  Boolean, default: false
  property :css,        Text, default: "{}"
  property :settings,   Text, default: "{}"
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }
  has n,   :folders,  :constraint => :set_nil
  has n,   :pages,    :constraint => :set_nil
  has n,   :users,    :through => Resource, :constraint => :destroy
  has n,   :group_users, :constraint => :set_nil
  has n,   :public_pages, :constraint => :destroy
  property :admin_id, Integer, required: false, default: 0
end

class GroupUser
  include DataMapper::Resource

  property :group_id, Integer, key: true, required: true
  property :user_id, Integer, key: true, required: true
  property :is_admin, Boolean, default: false
  
  def user;  User.get( self.attribute_get(:user_id))   end
  def group; Group.get(self.attribute_get(:group_id)) end

  property :role, Enum[:member, :editor, :admin], default: :member
end

class User
  has n, :group_users, :constraint => :set_nil
end

[ Page, Folder ].each { |r|
  eval %Q<
    class #{r}
      attr_accessor :user_id, :group_id
      property :group_id, Integer, required: false, default: 0
      property :user_id,  Integer, required: false, default: 0
    end
  >
}