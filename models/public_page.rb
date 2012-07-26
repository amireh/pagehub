class PublicPage
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :page
end