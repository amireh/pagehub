class User
  include DataMapper::Resource

  property :id, Serial
  property :email, String, required: true
  property :name, String, required: true
  property :nickname, String, default: ""
  property :password, String
  property :settings, Text, default: "{}"
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  # has n, :notebooks
  has n, :pages

  before :valid? do |_|
    self.nickname = self.name.to_s.sanitize if self.nickname.empty?

    true
  end

  def self.authenticate(email, password)
    pw = Digest::SHA1.hexdigest(password)
    User.first({ password: pw, email: email })
  end

end