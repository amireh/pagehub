class Folder
  include DataMapper::Resource

  attr_accessor :state

  property :id, Serial
  
  property :title,        String, length: 120, required: true
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  has n, :pages, :constraint => :set_nil
  belongs_to :user
  belongs_to :folder, default: nil, required: false
  belongs_to :group,  default: nil, required: false
  has n, :folders, :constraint => :set_nil

  validates_presence_of :title

  # Only the folder creator can destroy it, and only if it
  # doesn't contain folders created by others  
  before :destroy do |context|
    throw :halt unless deletable_by? state[:user]
  end

  def serialize(*args)
    pages = []
    self.pages.each { |p|
      pages << { title: p.title, id: p.id }
    }
    { id: id, parent: folder_id, title: title, pages: pages }
  end
  def to_json(*args)
    serialize.to_json
  end

  def is_child_of?(in_folder)
    if self.folder then
      return self.folder == in_folder ? true : self.folder.is_child_of?(in_folder)
    end

    false
  end

  def deletable_by?(u)
    if user != u 
      errors.add :_, "You are not authorized to delete folders created by others."
    elsif folders.count({ :user.not => u }) != 0
      errors.add :_, "The folder contains others created by someone else, they must be removed first."
    end

    errors.empty?
  end

  # def self.to_json
  #   {}.to_json
  # end
end