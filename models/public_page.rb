class PublicPage
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :group, default: nil, required: false
  belongs_to :page

  def url
    prefix = group ? group.name : user.nickname
    "/#{prefix}/#{page.compound_url}"
  end

end