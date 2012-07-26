class User
  include DataMapper::Resource

  property :id, Serial
  property :email, String, required: true
  property :name, String, required: true
  property :nickname, String, default: lambda { |*_| self.name.to_s.sanitize }
  property :password, String
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }

  # has n, :notebooks
  has n, :pages
end