class User
  include DataMapper::Resource

  property :id, Serial
  
  property :name,     String, length: 255, required: true
  property :provider, String, length: 255, required: true
  property :uid,      String, length: 255, required: true

  property :email,          String, length: 255, default: ""
  property :nickname,       String, length: 120, default: ""
  property :password,       String, length: 64
  property :settings,       Text, default: "{}"
  property :oauth_token,    Text
  property :oauth_secret,   Text
  property :extra,          Text
  property :auto_nickname,  Boolean, default: false
  property :created_at,     DateTime, default: lambda { |*_| DateTime.now }

  # has n, :notebooks
  has n, :pages, :constraint => :destroy
  has n, :folders, :constraint => :destroy
  has n, :groups, :through => Resource
  has n, :public_pages, :constraint => :destroy

  validates_presence_of :name, :provider, :uid

  before :valid? do |_|
    self.nickname = self.name.to_s.sanitize if self.nickname.empty?

    true
  end

  def all_pages
    pages = { folders: [] }
    self.folders(group: nil).each { |f| pages[:folders] << f.serialize }

    folderless = { title: "None", id: 0, pages: [] }
    self.pages.all(folder: nil, group: nil).each { |p| folderless[:pages] << p.serialize }
    pages[:folders] << folderless
    pages
  end
end