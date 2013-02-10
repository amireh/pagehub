# class Group
#   include DataMapper::Resource

#   Roles = [ :member, :editor, :admin ]

#   attr_accessor :state

#   property :id, Serial

#   property :name,       String, length: 120, unique: true, required: true
#   property :brief,      Text, default: "No description available."
#   property :title,      String, length: 120
#   property :is_public,  Boolean, default: false
#   property :css,        Text, default: ""
#   property :settings,   Text, default: "{}"
#   property :created_at, DateTime, default: lambda { |*_| DateTime.now }

#   has n,     :folders,  :constraint => :set_nil
#   has n,     :pages,    :constraint => :set_nil
#   has n,     :users,    :through => Resource, :constraint => :destroy
#   has n,     :group_users, :constraint => :destroy
#   has n,     :public_pages, :constraint => :destroy
#   belongs_to :admin, 'User', key: true

#   validates_presence_of :name

#   before :valid? do
#     self.name = self.title.sanitize
#   end

#   after :create do
#     gu = GroupUser.first_or_create({ group: self, user: self.creator })
#     gu.role = :admin
#     gu.save

#     true
#   end

  
#   def public_url
#     "/#{self.name}"
#   end

#   def url(suffix)
#     "/groups/#{self.id}#{suffix}"
#   end

#   def all_pages
#     c = { folders: [] }
#     folders.each { |f| c[:folders] << f.serialize }

#     folderless = { title: "None", id: 0, pages: [] }
#     pages.all(folder_id: nil).each { |p| folderless[:pages] << p.serialize }
#     c[:folders] << folderless

#     c
#   end
  
#   def home_page
#     pages.first({ title: "Home", folder_id: nil }) || pages.first({ folder_id: nil })
#   end

#   def is_browsable?
#     is_public
#   end

#   def browsable_pages(cnd = {}, order = [])
#     pages.all({ conditions: cnd.merge({ browsable: true }), order: [ :title.asc ] + order })
#   end
#   def browsable_folders(cnd = {}, order = [])
#     folders.all({ conditions: cnd.merge({ browsable: true }), order: [ :title.asc ] + order })
#   end

#   def on_resources(handlers, cnd = {}, coll = nil)
#     raise InvalidArgumentError unless handlers[:on_page] && handlers[:on_page].respond_to?(:call)
#     raise InvalidArgumentError unless handlers[:on_folder] && handlers[:on_folder].respond_to?(:call)

#     dump_pages = nil
#     dump_pages = lambda { |coll|
#       coll.each { |p| handlers[:on_page].call(p) }
#     }

#     unless coll
#       dump_pages.call(pages.all({ conditions: cnd.merge({ folder_id: nil }), order: [ :title.asc ] }))
#     end

#     dump_folder = nil
#     dump_folder = lambda { |f|
#       handlers[:on_folder].call(f)
#       dump_pages.call(f.pages.all({ conditions: cnd, order: [ :title.asc ]} ))
#       f.folders.all({ conditions: cnd }).each { |cf| dump_folder.call(cf) }
#       handlers[:on_folder_done].call(f) if handlers[:on_folder_done]
#     }

#     (coll || folders.all({ conditions: cnd.merge({ folder_id: nil }), order: [ :title.asc ] })).each { |f| dump_folder.call(f) }
#   end

#   def all_users
#     c = { users: [] }
#     self.group_users.each { |gu|
#       u = gu.user
#       c[:users] << { id: u.id, nickname: u.nickname, role: gu.role }
#     }
#     c
#   end

#   def role_of(user)
#     is_creator?(user) ? 'creator' : GroupUser.first({ group: self, user: user }).role.to_s
#   end

#   def has_admin?(user)
#     if gu = GroupUser.first({ group_id: self.id, user_id: user.id })
#       return gu.role == :admin
#     end
#     false
#   end
#   alias_method :is_admin?, :has_admin?

#   def has_member?(user)
#     return false if !user
#     self.users.each { |u| return true if user.nickname == u.nickname }
#     false
#   end
#   alias_method :is_member?, :has_member?

#   def has_editor?(user)
#     if gu = GroupUser.first({ group_id: self.id, user_id: user.id })
#       return gu.role != :member
#     end
#     false
#   end
#   alias_method :is_editor?, :has_editor?

#   def has_member_by_nickname?(nn)
#     self.users.each { |u| return true if nn == u.nickname }
#     false
#   end

#   def has_page?(page)
#     self.pages.each { |p| return true if p.id == page.id }
#     false
#   end

#   def has_page_by_title?(title)
#     self.pages.each { |p| return true if p.pretty_title == title}
#   end

#   def namespace
#     "/groups/#{self.id}"
#   end

#   def is_creator?(user)
#     admin.id == user.id
#   end

#   alias_method :creator, :admin
#   alias_method :has_creator?, :is_creator?
#   alias_method :is_master_admin?, :is_creator?

#   def admins()
#     users = []
#     GroupUser.all({ group: self, role: :admin }).each { |gu| users << gu.user }
#     users
#   end

#   def admin_nicknames
#     users = self.admins
#     users.each_with_index { |u, i| users[i] = u.nickname }
#     users
#   end

#   def is_master_admin?(user)
#     user.id == self.admin.id
#   end

#   def navigation_links
#     prefs = JSON.parse((self.settings || '{}'))
#     prefs["publishing"]["navigation_links"] || []
#   end
  
#   def preferences(*scope)
#     if scope.length == 1 && scope.first.is_a?(String)
#       scope = scope.first.split('.')
#     end
    
#     @preferences ||= Config.defaults.deep_merge(JSON.parse(self.settings))
#     scoped_preferences = @preferences
#     scope.each { |s| scoped_preferences = scoped_preferences[s.to_s] || {} }
#     scoped_preferences
#   end
  
#   alias_method :p, :preferences
# end