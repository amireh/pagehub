class Space
  include DataMapper::Resource

  MemberRoles = [ :member, :editor, :admin, :creator ]

  property :id, Serial

  property :brief,        Text,   default: ''
  property :is_public,    Boolean, default: false
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  has n,     :folders,          :constraint => :skip
  has n,     :pages,            :through => :folders, :constraint => :skip
  has n,     :space_users,      :constraint => :skip
  has n,     :users,            :through => Resource, :constraint => :skip
  has n,     :public_pages,     :constraint => :destroy

  belongs_to :creator, 'User'
  
  # alias_method :creator, :user
  
  is :preferencable
  is :titlable
  
  validates_uniqueness_of :title, :scope => [ :creator_id ],
    message: 'You already have a space with that title.'


  after :create do
    space_users.create({ user: self.creator, role: :creator })
    folders.create({ title: "None", creator: creator })
  end
  
  before :destroy do
    # puts "space[#{pretty_title}]: migrating orphaned pages authored by #{users.count} users"
    users.each { |u|
      next if u.id == creator.id
      
      user_pages = pages.all({ creator: u })
      if user_pages.empty?
        # puts "\tuser #{u.email} has authored no pages in #{pretty_title}, nothing to migrate"
        next
      end
      
      # puts "space: \tmigrating orphaned pages for #{u.email}"
      s = u.owned_spaces.create({ title: "Orphaned: #{title}" })
      f = s.root_folder
      user_pages.each { |p|
        p.update({ folder: f })
      }
    }
    
    space_users.destroy!
  end

  
  def root_folder
    folders.first({ folder_id: nil })
  end
  
  def public_url
    "/#{self.pretty_title}"
  end

  def url(suffix)
    "#{pretty_titlespace}#{suffix}"
  end
  
  def pretty_titlespace
    "/spaces/#{self.id}"
  end

  def folder_pages
    { folders: folders.collect { |f| f.serialize } }
  end
  
  def home_page
    root_folder.home_page
  end

  def is_browsable?
    is_public
  end

  def browsable_pages(cnd = {}, order = [])
    pages.all({ conditions: cnd.merge({ browsable: true }), order: [ :title.asc ] + order })
  end
  
  def browsable_folders(cnd = {}, order = [])
    folders.all({ conditions: cnd.merge({ browsable: true }), order: [ :title.asc ] + order })
  end

  # TODO: helperize this, seriously
  def on_resources(handlers, cnd = {}, coll = nil)
    raise InvalidArgumentError unless handlers[:on_page] && handlers[:on_page].respond_to?(:call)
    raise InvalidArgumentError unless handlers[:on_folder] && handlers[:on_folder].respond_to?(:call)

    dump_pages = nil
    dump_pages = lambda { |coll|
      coll.each { |p| handlers[:on_page].call(p) }
    }

    unless coll
      dump_pages.call(pages.all({ conditions: cnd.merge({ folder_id: nil }), order: [ :title.asc ] }))
    end

    dump_folder = nil
    dump_folder = lambda { |f|
      handlers[:on_folder].call(f)
      dump_pages.call(f.pages.all({ conditions: cnd, order: [ :title.asc ]} ))
      f.folders.all({ conditions: cnd }).each { |cf| dump_folder.call(cf) }
      handlers[:on_folder_done].call(f) if handlers[:on_folder_done]
    }

    (coll || folders.all({ conditions: cnd.merge({ folder_id: nil }), order: [ :title.asc ] })).each { |f| dump_folder.call(f) }
  end

  def all_users
    {
      users: space_users.collect { |entry|
        u = entry.user
        { id: u.id, nickname: u.nickname, role: entry.role }
      }
    }
  end

  def role_of(user)
    space_users.first({ user: user }).role.to_s
  end

  SpaceUser::Roles.flags.each { |role|

    define_method(:"has_#{role}?") do |user|
      unless entry = space_users.first({ user: user })
        return false
      end
      
      SpaceUser.weigh(entry.role) >= SpaceUser.weigh(role)
    end
    
    alias_method :"#{role}?", :"has_#{role}?"
    alias_method :"is_#{role}?", :"has_#{role}?"
    
    next if role == :creator
    
    define_method(:"add_#{role}") do |user|
      entry = space_users.first_or_create({ user: user })
      if entry.role != role
        entry.update({ role: role })
      end
    end
  }
  
  def has_member_by_nickname?(nn)
    users.select { |u| nn == u.nickname }.any?
  end

  def has_page?(page)
    pages.select { |p| p.id == page.id }.any?
  end

  def has_page_by_title?(title)
    pages.select { |p| p.pretty_title == title }
  end

  def is_creator?(user)
    creator.id == user.id
  end

  alias_method :has_creator?, :is_creator?
  alias_method :is_master_admin?, :is_creator?

  def admins()
    space_users.all({ role: :admin }).collect { |membership| membership.user }
  end

  def admin_nicknames
    admins.collect { |u| u.nickname }
  end

end