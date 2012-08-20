class Page
  include DataMapper::Resource

  property :id, Serial
  property :title, String, default: "Untitled"
  property :pretty_title, String, default: lambda { |r, _| r.title.sanitize }
  property :content, Text, default: "This page is empty!"
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  # belongs_to :notebook
  belongs_to :user
  has n, :tags, :through => Resource

  before :valid? do |_|
    self.pretty_title = self.title.sanitize

    true
  end

  def public_url(relative = false)
    prefix = relative ? "" : "http://www.pagehub.org"
    "#{prefix}/#{self.user.nickname}/#{self.pretty_title}"
  end
end