class Group
  include DataMapper::Resource

  attr_accessor :state

  property :id, Serial
  
  property :name,       String, length: 120, unique: true, required: true
  property :title,      String, length: 120
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  has n,     :folders,  :constraint => :set_nil
  has n,     :pages,    :constraint => :set_nil
  has n,     :users,    :through => Resource, :constraint => :destroy
  belongs_to :admin, 'User', key: true

  validates_presence_of :name

  before :valid? do
    self.name = self.title.sanitize
  end

  def all_pages
    c = { folders: [] }
    folders.each { |f| c[:folders] << f.serialize }

    folderless = { title: "None", id: 0, pages: [] }
    pages.all(folder_id: nil).each { |p| folderless[:pages] << p.serialize }
    c[:folders] << folderless

    c
  end

  def has_admin?(user)
    is_admin?(user)
  end

  def has_member?(user)
    self.users.each { |u| return true if user.nickname == u.nickname }
    false
  end

  def has_editor?(user)
    # TODO: implement
    has_member?(user)
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
    if gu = GroupUser.first({ group_id: self.id, user_id: user.id })
      return gu.is_admin
    end
    false
  end

  def is_creator?(user)
    admin.id == user.id
  end

  alias_method :has_creator?, :is_creator?
  alias_method :is_master_admin?, :is_creator?

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