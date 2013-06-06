require 'resolv'

class User
  include DataMapper::Resource

  # attr_accessor :editor, :password_confirmation
  attr_accessor :password_confirmation

  property :id, Serial

  property :name,     String, length: 255, required: true, message: 'We need a name for you.'
  property :provider, String, length: 255, required: true
  property :uid,      String, length: 255, default: lambda { |*_| UUID.generate }

  property :email,    String, length: 255, required: true,
    format: :email_address,
    messages: {
      presence:   'We need your email address.',
      format:     "Doesn't look like an email address to me..."
    }

  property :gravatar_email, String, length: 255, default: lambda { |r,_| r.email }
  property :nickname,       String, length: 120
  property :password,       String, length: 64
  property :oauth_token,    Text
  property :oauth_secret,   Text
  property :extra,          Text
  property :auto_nickname,  Boolean, default: false
  property :created_at,     DateTime, default: lambda { |*_| DateTime.now }

  is :preferencable, {}, PageHub::Config.defaults['user']

  has n, :owned_spaces, 'Space', :child_key => [ :creator_id ], :constraint => :destroy
  has n, :spaces, :through => Resource, :constraint => :skip
  has n, :space_users, :constraint => :skip
  has n, :pages,    :child_key => [ :creator_id ], :constraint => :destroy
  has n, :folders,  :child_key => [ :creator_id ], :constraint => :destroy
  # has n, :public_pages, :constraint => :skip
  # has n, :pages,    :constraint => :destroy
  # has n, :folders,  :constraint => :destroy
  has n, :email_verifications, :constraint => :destroy

  validates_presence_of :provider, :uid, :nickname
  validates_uniqueness_of :nickname, message: 'That nickname is not available.'

  validates_uniqueness_of :email, :scope => :provider,
    message: "There's already an account registered to this email address."

  validates_presence_of :password, :if => lambda { |u| u.provider == 'pagehub' }
  validates_length_of :password, within: 7..64, :if => lambda { |u| u.provider == 'pagehub' },
    message: "Password must be at least 7 characters long."

  # class << self
  #   attr_accessor :editor
  # end

  # def editor
  #   @editor || self.class.editor
  # end

  def create_default_space
    if owned_spaces.empty?
      return owned_spaces.create({ title: Space::DefaultSpace })
    end

    default_space
  end

  def default_space
    # owned_spaces.first({ title: Space::DefaultSpace })
    owned_spaces.first
  end

  def public_spaces(user)
    if !user
      spaces.all({ is_public: true })
    else
      owned_spaces.select { |s| s.member? user }
    end
  end

  after :create,  :create_default_space
  # after :save,    :create_default_space

  before :create do
    self.nickname = self.name.to_s.sanitize if (self.nickname || '').empty?
  end

  [ :save ].each { |advice|
    before advice do |_|
      if attribute_dirty?(:nickname)
        if nickname.sanitize != nickname
          errors.add :nickname, "Nicknames can only contain letters, numbers, dashes, and underscores."
          throw :halt
        end
      end

      if attribute_dirty?(:email)
        validate_email!(self.email, "primary", :email)
      end

      if attribute_dirty?(:password)
        if password != password_confirmation
          errors.add :password, "Passwords do not match."
          errors.add :password_confirmation, "Passwords do not match."
          throw :halt
        end

        attribute_set(:password, User.encrypt(password))
        attribute_set(:password_confirmation, User.encrypt(password_confirmation))
      end

      if attribute_dirty?(:gravatar_email)
        validate_email!(self.gravatar_email, "gravatar", :gravatar_email)
      end

      throw :halt unless errors.empty?

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

  def dashboard_url; '/' end

  def url(root = nil)
    "/users/#{id}"
  end

  def dashboard_url
    href
  end

  def settings_url
    '/settings'
  end

  def href
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

  def validate_email!(email, type, field)
    unless email.nil? || email.empty?
      unless email.is_email?
        errors.add(field, "Your #{type} email address does not appear to be valid.")
        throw :halt
      else
        unless validate_email_domain(email)
          errors.add(field, "Your #{type} email domain name appears to be incorrect.")
          throw :halt
        end
      end
    end
  end


end