require 'resolv'

class User
  include DataMapper::Resource

  # attr_accessor :editor, :password_confirmation
  attr_accessor :password_confirmation

  property :id, Serial

  property :name,     String, length: 255, required: true
  property :provider, String, length: 255, required: true
  property :uid,      String, length: 255, default: lambda { |*_| UUID.generate }

  property :email,          String, length: 255, default: ""
  property :gravatar_email, String, length: 255, default: lambda { |r,_| r.email }
  property :nickname,       String, length: 120, default: ""
  property :password,       String, length: 64
  property :oauth_token,    Text
  property :oauth_secret,   Text
  property :extra,          Text
  property :auto_nickname,  Boolean, default: false
  property :created_at,     DateTime, default: lambda { |*_| DateTime.now }

  is :preferencable

  has n, :owned_spaces, 'Space', :child_key => [ :creator_id ], :constraint => :destroy
  has n, :spaces, :through => Resource, :constraint => :skip
  has n, :space_users, :constraint => :skip
  has n, :pages,    :child_key => [ :creator_id ], :constraint => :destroy
  has n, :folders,  :child_key => [ :creator_id ], :constraint => :destroy
  # has n, :public_pages, :constraint => :skip
  # has n, :pages,    :constraint => :destroy
  # has n, :folders,  :constraint => :destroy
  has n, :email_verifications, :constraint => :destroy

  validates_presence_of :name, :provider, :uid

  # class << self
  #   attr_accessor :editor
  # end
  
  # def editor
  #   @editor || self.class.editor
  # end
  
  def create_default_space
    owned_spaces.create({ title: Space::DefaultSpace }) if owned_spaces.empty?
  end
  
  def default_space
    owned_spaces.first({ title: Space::DefaultSpace })
  end
  
  after :create,  :create_default_space
  # after :save,    :create_default_space
  
  [ :create, :save ].each { |advice|
    before advice do |_|
      self.nickname = self.name.to_s.sanitize if self.nickname.empty?

      # validate_email!(self.email, "primary")
      # validate_email!(self.gravatar_email, "gravatar")

      errors.empty?
    end
  }

  def demo?
    name == "PageHub Demo"
  end

  before :destroy do
    space_users.destroy!
  end

  class << self
    # TODO: this needs to be changed
    def encrypt(pw)
      Digest::SHA1.hexdigest(pw || "")
    end
  end

  def all_pages
    pages = { folders: [] }
    self.folders(group: nil).each { |f| pages[:folders] << f.serialize }

    folderless = { title: "None", id: 0, pages: [] }
    self.pages.all(folder: nil, group: nil).each { |p| folderless[:pages] << p.serialize }
    pages[:folders] << folderless
    pages
  end

  def namespace
    ""
  end

  def profile_url
    "/profiles/#{self.nickname}"
  end

  def public_url
    "/#{self.nickname}"
  end

  def verified?(address)
    if address == self.email
      unless ev = self.email_verifications.first({ primary: true })
        return false
      end
    else
      unless ev = self.email_verifications.first({ address: address, primary: false })
        return false
      end
    end

    ev.verified?
  end

  def verify_address(address)
    unless ev = self.email_verifications.first_or_create({ address: address, primary: address == self.email })
      errors.add :email_verifications, ev.collect_errors
      throw :halt
    end

    ev
  end

  def awaiting_verification?(address)
    if ev = self.email_verifications.first({ address: address })
      return ev.pending?
    end
  end
  
  private

  # Validates an email domain using Ruby's DNS resolver.
  # Thanks to:
  # => http://www.buildingwebapps.com/articles/79182-validating-email-addresses-with-ruby
  def validate_email_domain(email)
    domain = email.match(/\@(.+)/)[1]
    Resolv::DNS.open do |dns|
      @mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX)
    end
    @mx.size > 0 ? true : false
  end

  def validate_email!(email, type)
    unless email.nil? || email.empty?
      unless email.is_email?
        errors.add(:email, "Your #{type} email address does not appear to be valid.")
        throw :halt
      else
        unless validate_email_domain(email)
          errors.add(:email, "Your #{type} email domain name appears to be incorrect.")
          throw :halt
        end
      end
    end
  end
  

end