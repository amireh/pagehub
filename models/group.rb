class Group
  include DataMapper::Resource

  property :id, Serial
  
  property :name, String, unique: true, required: true
  property :title, String
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  # has n, :notebooks
  has n, :users, :through => Resource
  has n, :pages, :through => Resource

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
end