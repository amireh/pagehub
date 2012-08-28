module PageHub
  class Resource
    include DataMapper::Resource

    storage_names[:default] = "resources"

    property :id,           Serial
    property :title,        String, length: 120, default: lambda { |r, _| "Untitled ##{Resource.random_suffix}" }
    property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
    property :type,         Discriminator
    property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

    belongs_to :folder, default: nil
    belongs_to :user
    has n, :shares

    validates_presence_of :title

    # before :valid? do
    #   self.pretty_title = self.title.sanitize

    #   true
    # end

    def serialize(*args)
      { id: self.id, title: self.title }
    end

    def to_json(*args)
      serialize.to_json
    end

    def self.random_suffix
      Base64.urlsafe_encode64(Random.rand(12345 * 100).to_s)
    end

    def public_url(relative = false)
      prefix = relative ? "" : "http://www.pagehub.org"
      "#{prefix}/#{self.user.nickname}/#{self.pretty_title}"
    end

  end
end