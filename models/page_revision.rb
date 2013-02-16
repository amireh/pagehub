class Page
  class Revision
    include DataMapper::Resource

    default_scope(:default).update(:order => [ :created_at.asc ])

    class NothingChangedError < RuntimeError; end
    class InvalidContextError < RuntimeError; end
    class BadPatchError < RuntimeError; end
    class PatchTooBigError < RuntimeError; end
    
    MaxPatchSize = 102400 # 100 KBytes
    
    include ::PageHub::Helpers

    attr_writer :context
    
    if ENV['RACK_ENV'] == 'test'
      attr_accessor :blob
    end
    
    property :id,         Serial
    property :blob,       Binary, length: MaxPatchSize, writer: :private # 100 KByte
    property :version,    String, length: 41, writer: :private
    property :created_at, DateTime, default: lambda { |*_| DateTime.now }
    property :additions,  Integer
    property :deletions,  Integer
    property :patchsz,    Integer

    belongs_to :page
    belongs_to :editor, 'User'

    before :create do |*_|
      if !@context || !@context[:content]
        raise InvalidContextError, "Revision context must be populated with the current page content."
      end

      if !page.carbon_copy
        raise InvalidContextError, "Page must have a CC for a revision to be generated."
      end
      
      # puts "Generating diff between #{page.carbon_copy.content} and #{@context[:content]}..."
      diff = Diff::LCS.diff(page.carbon_copy.content.split("\n"), @context[:content].split("\n"))

      # has the content changed?
      if diff.length == 0
        raise NothingChangedError
      end
      # puts "#{diff.length} lines have changed"
      
      # serialize the patch
      serialized_patch = Marshal.dump(diff)

      # make sure we're within the sanity size
      # puts "patch length: #{serialized_patch.length}"
      if serialized_patch.length >= MaxPatchSize
        raise PatchTooBigError
      end

      self.patchsz = serialized_patch.length
      self.blob = serialized_patch
      self.version = Digest::SHA1.hexdigest(serialized_patch)

      changes = { :additions => 0, :deletions => 0 }
      diff.each { |changeset|
        changeset.each { |d|
          d.action == '-' ? changes[:deletions] += 1 : changes[:additions] += 1
        }
      }

      self.additions = changes[:additions]
      self.deletions = changes[:deletions]

      # puts "New version: #{self.version}"

      true
    end

    def info
      "#{pluralize(self.additions, 'addition')} and #{pluralize(self.deletions, 'deletion')}."
    end

    # Gets the revision right after this one, if any
    def next
      self.page.revisions.first({ :created_at.gt => self.created_at })
    end

    # Gets the revision right before this one, if any
    def prev
      self.page.revisions.last({ :created_at.lt => self.created_at })
    end

    def url
      "#{page.url(true)}/revisions/#{id}"
    end
    
    def href
      "#{page.href}/revisions/#{id}"
    end

    def apply(string)
      roll(:backward, string)
    end

    def apply!(string)
      string = apply(string); string
    end

    def pretty_version
      version[-8..version.length]
    end

    private

    # Rolling forward is currently unused.
    def roll(direction, str)
      diff = nil

      begin
        diff = Marshal.load(self.blob)
      rescue Exception => e
        raise BadPatchError,
              "Unable to load patch: #{e.class}##{e.message}, revision: #{self.inspect}"
      end
      
      begin
        case direction
        when :forward
          Diff::LCS.patch!(str.split("\n"), diff).join("\n")
        when :backward
          Diff::LCS.unpatch!(str.split("\n"), diff).join("\n")
        else
          raise "#roll can only go :forward or :backword, but was told to roll in #{direction}"
        end
      rescue Exception => e
        raise BadPatchError,
              "Patch might be corrupt: #{e.class}##{e.message}, revision: #{self.inspect}"
      end
    end
  end
end