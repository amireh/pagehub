class EmailVerification
  include DataMapper::Resource

  property    :salt, String, length: 255
  property    :address, String, length: 255, unique: true, allow_nil: false
  property    :created_at, DateTime, default: lambda { |*_| DateTime.now }
  property    :status, Enum[ :pending, :expired, :verified ], default: :pending
  property    :primary, Boolean, default: false # used for quick look-ups
  belongs_to  :user, key: true

  before :create do |ctx|
    puts "Generating salt..."
    self.salt = Base64.urlsafe_encode64( self.user.nickname + Random.rand(1234).to_s + Time.now.to_s)
    # self.save
    true
  end

  def expired?
    status == :expired
  end
  def pending?
    status == :pending
  end
  def verified?
    status == :verified
  end

  def verify!
    self.update({ status: :verified })
  end
  
  def expire!
    self.update({ status: :expired })
  end

  def url
    "/users/#{self.user.id}/verify/#{self.salt}"
  end

end