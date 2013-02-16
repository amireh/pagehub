class Folder
  include DataMapper::Resource

  # attr_writer :editor
  DefaultFolder = 'None'

  property :id, Serial

  # Whether the folder is browsable in a public group listing
  property :browsable,    Boolean, default: true
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :space
  belongs_to :folder, required: false, default: lambda { |f, *_| f.space && f.space.root_folder }
  belongs_to :creator, 'User'
  
  has n, :pages,    :constraint => :destroy
  has n, :folders,  :constraint => :destroy

  # validates_with_method :folder,  method: :validate_hierarchy!
  # validates_with_method :title,   method: :validate_title!
  validates_uniqueness_of :title, :scope => [ :space_id, :folder_id ],
    message: 'You already have a folder with that title.'

  is :titlable

  # Only the folder creator can destroy it, and only if it
  # doesn't contain folders created by others
  # before :destroy, :deletable_by?
  # before :destroy, :nullify_references
  
  [ :save, :update ].each { |advice|
    before advice.to_sym do |*args|
      validate_hierarchy!
      # validate_title!

      throw :halt unless errors.empty?
    end
  }
  
  # def editor
  #   @editor || User.editor
  # end
    
  def create_homepage
    pages.create({ title: "README", creator: creator })
  end
    
  def serialize
    serialized_pages = pages.collect { |p| p.serialize }
    out = { id: id, title: title, pages: serialized_pages }
    if folder
      out[:parent] = folder.id
    end
    out
  end
  
  def empty?(scope = :public)
    self.folders.empty? && self.pages.all({ browsable: true }).empty?
  end
  
  def has_homepage?()
    pages({ title: [ "Home", "README" ] }).first
  end
  
  def homepage
    pages.first({ title: [ "Home", "README" ] }) || pages.first
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
  
  def siblings
    if !folder
      return []
    end
    
    folder.folders.all({ :id.not => self.id })
    # space.folders({ folder: self.folder, :id.not => self.id })
  end
  
  def ancestors
    parents = []
    p = self
    while p = p.folder do; parents << p end
    parents
  end

  def descendants(with_pages = false)
    folders.collect { |f| f.descendants }.flatten + folders + (with_pages ? pages : [])
  end

  def url(root = false)
    root ? "/folders#{id}" : "#{space.url(true)}/folders/#{id}"
  end
      
  def href
    folder ? folder.href + "/#{pretty_title}" : space.href
  end
  
  def deletable_by?(editor)
    if !space.is_member?(editor)
      [ false, "You are not authorized to delete folders in this space." ]
    elsif creator.id != editor.id
      [ false, "You are not authorized to delete folders created by others." ]
    elsif folders.all({ :creator.not => creator }).any?
      [ false, "The folder contains others created by someone else, they must be removed first." ]
    else
      true
    end    
  end
  # pre-destroy hook:
  #
  # If this folder is attached to another, we will
  # move all its children pages and folders to that parent,
  # otherwise they are orphaned into the root folder.
  def nullify_references(context = :default)
    new_parent = self.folder

    if new_parent
      self.pages.all({ title: "README" }).update({ title: "#{self.title} - README" })
      self.pages.update!(folder: new_parent)
      self.folders.update!(folder: new_parent)
    end
    
    refresh
  end
  
  private

  # pre-destroy validation hook:
  #
  # Folders are deletable only by their authors and  only when all their
  # children are owned by that same author.
  # def deletable_by?(context = :default)
  #   if !folder
  #     errors.add :id, "You can not remove the root folder."
  #   elsif !editor
  #     errors.add :editor, "An editor must be assigned before attempting to remove a folder."
  #   elsif !space.is_member?(editor)
  #     errors.add :editor, "You are not authorized to delete folders in this space."
  #   elsif creator.id != editor.id
  #     errors.add :creator, "You are not authorized to delete folders created by others."
  #   elsif folders.all({ :creator.not => creator }).any?
  #     errors.add :folders, "The folder contains others created by someone else, they must be removed first."
  #   end

  #   throw :halt unless errors.empty?
  # end

 

  # Checks for placement of a folder
  def validate_hierarchy!
    if folder
      # prevent the folder from being its own parent
      if folder.id == self.id then
        errors.add :folder_id, "You cannot add a folder to itself!"        

      # or a parent being a child of one of its children
      elsif folder.is_child_of?(self) then
        errors.add :folder_id, "Folder '#{title}' currently contains '#{folder.title}', it cannot become its child." 
      elsif folder.space != self.space then
        errors.add :folder_id, "Parent folder is not in the same space!"
      end
    else
      # no folder?
      if space.folders.count > 0
        errors.add :folder_id, "A folder must be set inside another."
      end
    end
    
    errors.empty?
  end

end