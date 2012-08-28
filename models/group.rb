class Group
  include DataMapper::Resource

  property :id, Serial
  
  property :name,       String, length: 120, unique: true, required: true
  property :title,      String, length: 120
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  has n,     :users, :through => Resource
  has n,     :pages, :through => Resource
  belongs_to :admin, 'User', key: true

  validates_presence_of :name

  def has_member?(user)
    self.users.each { |u| return true if user.nickname == u.nickname }
    false
  end

  def has_member_by_nickname?(nn)
    self.users.each { |u| return true if nn == u.nickname }
    false
  end

  def has_page?(page)
    self.pages.each { |p| return true if p.id == page.id }
    false
  end

  def has_page_by_title?(title)
    self.pages.each { |p| return true if p.pretty_title == title}
  end

  def is_admin?(user)
    GroupUser.first({ group_id: self.id, user_id: user.id }).is_admin
  end

  def admins()
    users = []
    GroupUser.all({ group_id: self.id, is_admin: true }).each { |gu| users << gu.user }
    users
  end

  def admin_nicknames
    users = self.admins
    users.each_with_index { |u, i| users[i] = u.nickname }
    users
  end

  def is_master_admin?(user)
    user.id == self.admin.id
  end

end