class PublicPage
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :space, :key => true
  belongs_to :page, :key => true

  def url
    prefix = group ? group.name : user.nickname
    "/#{prefix}/#{page.compound_url}"
  end

end