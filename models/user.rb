require 'resolv'

class User
  include DataMapper::Resource

  property :id, Serial

  property :name,     String, length: 255, required: true
  property :provider, String, length: 255, required: true
  property :uid,      String, length: 255, required: true

  property :email,          String, length: 255, default: ""
  property :gravatar_email, String, length: 255, default: lambda { |r,_| r.email }
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
  has n, :email_verifications, :constraint => :destroy

  validates_presence_of :name, :provider, :uid

  before :valid? do |_|
    self.nickname = self.name.to_s.sanitize if self.nickname.empty?

    validate_email!(self.email, "primary")
    validate_email!(self.gravatar_email, "gravatar")

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
      unless email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
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