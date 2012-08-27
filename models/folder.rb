class Folder
  include DataMapper::Resource

  property :id, Serial
  
  property :title,        String, length: 120, required: true
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  has n, :pages, :constraint => :set_nil
  belongs_to :user
  belongs_to :folder, default: 0, required: false

  validates_presence_of :title

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

  # def self.to_json
  #   {}.to_json
  # end
end