class User
  include DataMapper::Resource

  property :id, Serial
  
  property :name, String, required: true
  property :provider, String, required: true
  property :uid, String, required: true

  property :email, String, default: ""
  property :nickname, String, default: ""
  property :password, String
  property :settings, Text, default: "{}"
  property :oauth_token, Text
  property :oauth_secret, Text
  property :extra, Text
  property :auto_nickname, Boolean, default: false
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  # has n, :notebooks
  has n, :pages
  has n, :groups, :through => Resource

  validates_presence_of :name, :provider, :uid

  before :valid? do |_|
    self.nickname = self.name.to_s.sanitize if self.nickname.empty?

    true
  end

end