class Folder
  include DataMapper::Resource

  attr_writer :operating_user

  property :id, Serial

  property :title,        String, length: 120, required: true
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  # Whether the folder is browsable in a public group listing
  property :browsable,    Boolean, default: true
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :folder, default: nil, required: false
  belongs_to :group,  default: nil, required: false
  has n, :pages,    :constraint => :skip
  has n, :folders,  :constraint => :skip

  validates_presence_of :title
  validates_length_of   :title, :within => 3..120

  before :valid? do
    self.pretty_title = self.title.sanitize
  end

  # Only the folder creator can destroy it, and only if it
  # doesn't contain folders created by others
  before :destroy, :deletable_by?
  before :destroy, :nullify_references

  [ :save, :update ].each { |advice|
    before advice.to_sym do |*args|
      validate_hierarchy!
      validate_title!

      throw :halt unless errors.empty?

      true
    end
  }

  def serialize
    pages = []; self.pages.each { |p| pages << p.serialize }
    out = { id: id, title: title, pages: pages }
    if folder
      out[:parent] = folder.id
    end
    out
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

  def public_url(relative = true)
    scope = group ? group.public_url : user.public_url
    path = [ pretty_title ]
    p = folder
    while p do path.insert(0,p.pretty_title); p = p.folder end

    return "#{scope}/#{path.join('/')}"
  end

  private

  # pre-destroy validation hook:
  #
  # Folders are deletable only by their authors and  only when all their
  # children are owned by that same author.
  def deletable_by?(context = :default)
    if user != @operating_user
      errors.add :_, "You are not authorized to delete folders created by others."
    elsif folders.count({ :user.not => @operating_user }) != 0
      errors.add :_, "The folder contains others created by someone else, they must be removed first."
    end

    # puts "Folder: in #{context.state} checking if i can be deleted, my state: #{@state.inspect}"

    # if errors.empty?
      # puts "Folder #{id} can be deleted"
    # else
      # puts "Folder #{id} can NOT be deleted because: #{collect_errors}"
    # end

    throw :halt unless errors.empty?
  end

  # pre-destroy hook:
  #
  # If this folder is attached to another, we will
  # move all its children pages and folders to that parent,
  # otherwise they are orphaned into the general folder.
  def nullify_references(context = :default)
    new_parent = self.folder

    self.pages.update!(folder: new_parent)
    self.folders.update!(folder: new_parent)
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