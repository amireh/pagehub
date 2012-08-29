class Page
  include DataMapper::Resource
  
  attr_writer :operating_user

  property :id,           Serial
  property :title,        String, length: 120, default: lambda { |r, _| "Untitled ##{Page.random_suffix}" }
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  property :content,      Text,   default: "This page is empty."
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :folder, default: nil, required: false
  belongs_to :group,  default: nil, required: false
  has n, :public_pages, :constraint => :destroy

  validates_presence_of :title
  validates_length_of   :title, :within => 3..120

  before :valid? do
    self.pretty_title = self.title.sanitize
  end

  before :destroy, :deletable_by? 

  def compound_url
    f = folder
    ancestry = []
    while f
      ancestry.insert(0,f.pretty_title)
      f = f.folder
    end

    ancestry << pretty_title
    ancestry.join('/')
  end

  def editable_by?(u = nil)
    u ||= current_user
    self.user == u || self.group && self.group.has_editor?(u)
  end

  def public_url(relative = false)
    prefix = relative ? "" : "http://www.pagehub.org"
    "#{prefix}/#{self.user.nickname}/#{self.pretty_title}"
  end

  def self.random_suffix
    Base64.urlsafe_encode64(Random.rand(12345 * 100).to_s)
  end

  def serialize
    { id: id, title: title, folder: folder_id || 0 }
  end

  def to_json(*args)
    serialize.to_json
  end

  private

  # pre-destroy validation hook:
  #
  # Pages are deletable only by their authors.
  def deletable_by?(context = :default)
    if user != @operating_user
      errors.add :_, "Pages can be deleted only by their author."
    end

    throw :halt unless errors.empty?
  end
end