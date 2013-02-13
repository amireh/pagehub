class Space
  include DataMapper::Resource
  # include Sentinel

  DefaultSpace = 'Personal'
  
  # attr_writer :editor

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
  
  is :preferencable, {}, PageHub::Config.defaults
  is :titlable
  
  # def editor
  #   @editor || User.editor
  # end

  # def authorized_editor(*args)
  #   if !editor
  #     raise DataMapper::MissingOperatorError.new(:editor)
  #   elsif !admin?(editor)
  #     errors.add :editor, "You are not authorized to modify memberships of this space."
  #   end
    
  #   errors.empty?
  # end
    
  validates_uniqueness_of :title, :scope => [ :creator_id ],
    message: 'You already have a space with that title.'

  after :create do
    space_users.create({ user: creator, role: :creator })
    f = folders.create({ title: Folder::DefaultFolder, creator: creator })
    f.create_homepage
  end

  # the default space should never be destroyed
  # before :destroy do
  #   if default?
  #     errors.add :id, 'You can not remove the default space!'
  #     throw :halt
  #   end
  # end
  
  # before :destroy, :orphanize
  before :destroy do
    folders.destroy
    space_users.destroy!
  end
  
  # guard :destroy, with: :authorized_editor
    
  def root_folder
    folders.first({ folder_id: nil })
  end
  alias_method :root, :root_folder
  
  def public_url
    "#{user.public_url}/#{self.pretty_title}"
  end

  def url(suffix)
    "#{namespace}#{suffix}"
  end
  
  def namespace
    "#{user.namespace}/spaces/#{self.id}"
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
    pages.all({ conditions: cnd.merge({ browsable: true }), order: order })
  end
  
  def browsable_folders(cnd = {}, order = [])
    folders.all({ conditions: cnd.merge({ browsable: true }), order: order })
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
    if entry = space_users.first({ user: user })
      entry.role.to_s
    else
      nil
    end
  end

  SpaceUser::Roles.flags.each { |role|
    
    # is_member?
    # has_member?
    # member?
    define_method(:"has_#{role}?") do |user|
      unless entry = space_users.first({ user: user })
        return false
      end
      
      SpaceUser.weigh(entry.role) >= SpaceUser.weigh(role)
    end
    
    alias_method :"#{role}?",     :"has_#{role}?"
    alias_method :"is_#{role}?",  :"has_#{role}?"
    
    next if role == :creator
    
    # add_member
    define_method(:"add_#{role}") do |user|
      entry = space_users.first_or_create({ user: user }, { role: role })
      if entry.role != role
        entry.update!({ role: role })
      end
      
      entry.saved?
    end
    
    # members
    define_method("#{role}s") do
      space_users.all({ role: role }).collect { |membership| membership.user }
    end
    
    # guard :"add_#{role}", with: :authorized_editor
  }
  
  # Members that can write, edit, and remove pages and folders.
  def authors
    space_users.all({ :role.not => :member }).collect { |m| m.user }
  end
  
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
    user && creator.id == user.id
  end

  def default?
    title == DefaultSpace
  end
  
  def orphanize
    authors.each { |u|
      next if u.id == creator.id
      next if u.is_on? 'spaces.no_orphanize'
      
      user_pages = pages.all({ creator: u })

      next if user_pages.empty?

      s = u.owned_spaces.first_or_create({
        title: "Orphaned: #{title}"
      }, {
        brief: brief
      })
      
      f = s.root_folder
      
      user_pages.each { |p|
        p.update({ folder: s.root_folder })
      }
    }
    refresh
  end
end