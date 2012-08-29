class Folder
  include DataMapper::Resource

  attr_accessor :state

  property :id, Serial
  
  property :title,        String, length: 120, required: true
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :folder, default: nil, required: false
  belongs_to :group,  default: nil, required: false
  has n, :pages,    :constraint => :set_nil
  has n, :folders,  :constraint => :set_nil

  validates_presence_of :title
  validates_length_of   :title, :within => 3..120

  before :valid? do
    self.pretty_title = self.title.sanitize
  end

  # Only the folder creator can destroy it, and only if it
  # doesn't contain folders created by others  
  before :destroy do |context|
    # @state ||= group.state

    puts "Folder: in #{context.state} checking if i can be deleted, my state: #{@state.inspect}"
    # throw :halt unless deletable_by? @state[:user]
  end

  [ :save, :update ].each { |advice|
    before advice.to_sym do |*args|
      # puts "Validating folder in #{advice}..."

      validate_hierarchy!
      validate_title!

      # puts "#{errors.empty? ? 'is valid!' : 'isn\'t valid!'}"
      
      throw :halt unless errors.empty?

      true
    end
  }

  def serialize
    pages = []; self.pages.each { |p| pages << p.serialize.delete!(:folder) }
    { id: id, parent: folder ? folder.id : nil, title: title, pages: pages }
  end

  def to_json
    serialize.to_json
  end

  def is_child_of?(in_folder)
    if self.folder then
      return self.folder.id == in_folder.id ? true : self.folder.is_child_of?(in_folder)
    end

    false
  end

  # Folders are deletable only by their authors and
  # only when all their children are owned by that same author.
  def deletable_by?(u)
    if user != u 
      errors.add :_, "You are not authorized to delete folders created by others."
    elsif folders.count({ :user.not => u }) != 0
      errors.add :_, "The folder contains others created by someone else, they must be removed first."
    end

    if errors.empty?
      puts "Folder #{id} can be deleted"
    else
      puts "Folder #{id} can NOT be deleted because: #{collect_errors}"
    end

    errors.empty?
  end

  # Folder title must be unique within its scope (user or group)
  def validate_title!
    scope, extra = nil, {}
    if group
      scope = group
    else
      scope = user; extra = { group: nil }
    end

    unless scope.folders.count({ pretty_title: self.pretty_title, :id.not => self.id }.merge(extra)) == 0
      errors.add :title, "That name is unavailable."
    end
  end

  # A folder cannot be its own parent, or a child
  # of one of its children
  def validate_hierarchy!
    if folder 
      # prevent the folder from being its own parent
      if folder.id == self.id then
        errors.add :folder_id, "You cannot add a folder to itself!"

      # or a parent being a child of one of its children
      elsif folder.is_child_of?(self) then
        errors.add :folder_id, 
          "Folder '#{title}' currently contains '#{folder.title}', it cannot become its child."
      end
    end
  end

end