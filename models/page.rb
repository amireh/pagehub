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
    page = self
    p page.title
    p page.pretty_title
    page.pretty_title = page.title.sanitize

    true
  end
end