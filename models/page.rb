class Page
  include DataMapper::Resource
  
  property :id,           Serial
  property :title,        String, length: 120, default: lambda { |r, _| "Untitled ##{Page.random_suffix}" }
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  property :content,      Text, default: "This page is empty!"
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :folder, default: nil, required: false
  belongs_to :group,  default: nil, required: false
  # has n,      :groups, :through => Resource

  before :valid? do |context|
    self.pretty_title = self.title.sanitize

    true
  end

  def deletable_by?(u = nil)
    u ||= current_user
    self.user == u
  end

  def editable_by?(u = nil)
    u ||= current_user
    self.user == u
  end

  def public_url(relative = false)
    prefix = relative ? "" : "http://www.pagehub.org"
    "#{prefix}/#{self.user.nickname}/#{self.pretty_title}"
  end

  def self.random_suffix
    Base64.urlsafe_encode64(Random.rand(12345 * 100).to_s)
  end

  # def group_names()
  #   groups = []; self.groups.each { |g| groups << g.name }; groups
  # end

  def serialize
    { id: id, title: title, folder: folder_id || 0 }
  end

  def to_json(*args)
    serialize.to_json
  end
end