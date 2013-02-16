require 'diff/lcs'
class Revision
  include DataMapper::Resource

  default_scope(:default).update(:order => [ :created_at.asc ])

  class NothingChangedError < RuntimeError; end
  class InvalidContextError < RuntimeError; end

  include ::PageHub::Helpers

  attr_writer :context

  property :id, Serial
  property :blob, Binary, length: 102400, writer: :private # 100 KByte
  property :version, String, length: 41, writer: :private
  property :created_at, DateTime, default: lambda { |*_| DateTime.now }
  property :additions, Integer
  property :deletions, Integer
  property :patchsz, Integer

  belongs_to :page
  belongs_to :editor, 'User'

  before :valid? do
    if !@context || !@context[:content]
      errors.add :context, "Revision context must be populated with the current page content."
      throw :halt
    end

    # puts "Generating diff..."
    diff = Diff::LCS.diff(page.carbon_copy.content.split("\n"), @context[:content].split("\n"))

    # has the content changed?
    if diff.length == 0
      raise NothingChangedError.new
    end

    # serialize the diff
    serialized_patch = Marshal.dump(diff)

    # make sure we're within the sanity size
    if serialized_patch.length >= 102400
      errors.add :blob, "The differences are too great to be stored."
      throw :halt
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
    page.revisions.first({ :created_at.gt => self.created_at })
  end

  # Gets the revision right before this one, if any
  def prev
    page.revisions.last({ :created_at.lt => self.created_at })
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
      raise RuntimeError "Unable to load patch: #{e.message}, revision: #{self.inspect}"
    end
    
    begin
      if direction == :forward
        return Diff::LCS.patch!(str.split("\n"), diff).join("\n")
      elsif direction == :backward
        return Diff::LCS.unpatch!(str.split("\n"), diff).join("\n")
      else
        puts "ERROR: revision::roll can only go :forward or :backword, but was told to roll in #{direction}"
        return nil
      end
    rescue Exception => e
      raise RuntimeError "Patch might be corrupt: #{e.message}, revision: #{self.inspect}"
    end
  end
end