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
  has n, :pages
  has n, :groups, :through => DataMapper::Resource
  has n, :folders

  validates_presence_of :name, :provider, :uid

  before :valid? do |_|
    self.nickname = self.name.to_s.sanitize if self.nickname.empty?

    true
  end

  def all_pages
    c = { folders: [] }
    folders.each { |f| c[:folders] << f.serialize }

    # pages in no folder
    folderless = { title: "None", id: 0, pages: [] }
    pages.all(folder_id: nil).each { |p| folderless[:pages] << p.serialize }
    c[:folders] << folderless

    c
  end
end