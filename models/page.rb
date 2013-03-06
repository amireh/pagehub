require 'digest/sha1'
require 'base64'

class Page
  include DataMapper::Resource

  class CarbonCopy
    include DataMapper::Resource

    property :content, Text, default: "", length: 2**24-1
    belongs_to :page, key: true
  end

  class Revision
  end

  # attr_writer :editor

  default_scope(:default).update(:order => [ :title.asc ])

  property :id,           Serial
  property :content,      Text,   default: "", length: 2**24-1 # 16 MBytes (MySQL MEDIUMTEXT)

  # browsable: whether the folder is browsable in a public group space,
  # note that this has lower priority than the public page status;
  # if the page _does_ have a PublicPage record, then it will still
  # be accessible directly via its public URL, but it will simply not
  # be browsable via the group space
  property :browsable,    Boolean, default: true

  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }
  property :updated_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :folder
  belongs_to :creator, 'User'

  has n, :public_pages, :constraint => :destroy
  has n, :revisions,    Page::Revision,    :constraint => :destroy
  has 1, :carbon_copy,  Page::CarbonCopy,  :constraint => :destroy

  is :titlable, default: lambda { |r, _| "Untitled ##{Page.random_suffix}" }
  validates_uniqueness_of :title, :scope => [ :folder_id ],
    message: 'You already have such a page in that folder.'

  validates_with_method :title, :method => :ensure_hierarchical_resource_title_uniqueness

  def ensure_hierarchical_resource_title_uniqueness
    if folder.folders.first({ pretty_title: self.pretty_title }).nil?
      return true
    end

    errors.add :title, "You have a folder titled #{self.title} in the same folder you're trying to create the page in."
    throw :halt
  end

  before :valid? do
    self.updated_at = DateTime.now

    true
  end

  # def editor
  #   @editor || User.editor
  # end

  alias_method :cc, :carbon_copy

  # [ :update, :save ].each { |advice|
  #   before advice do |context|
  #   end
  # }

  before :save do
    # reserved names only apply to the root-level resources
    if !folder.folder && !resource_title_available?(self.title)
      errors.add :title, "That title is reserved for internal usage."
      throw :halt
    end
  end

  after :create, :init_cc

  def init_cc(context = nil)
    # Don't initialize the CC with our content because
    # we want the first revision to reflect the entire
    # changes the post was first created with.
    self.carbon_copy = CarbonCopy.new
    self.carbon_copy.page = self
    self.carbon_copy.save! # make sure to use the bang version here
  end

  def browsable_by?(user)
    (browsable && folder.browsable_by?(user)) || space.member?(user)
  end

  # before :destroy, :deletable_by?

  def generate_revision(new_content, editor)
    if !saved?
      errors.add :revisions, "Page revisions can not be generated from new pages."
      return false
    end

    if !new_content
      return true
    end

    rv = revisions.new
    rv.context = { content: new_content }
    rv.editor = editor
    unless rv.save
      errors.add :revisions, rv.all_errors
      return false
    end

    self.carbon_copy.update!({ content: new_content })

    true
  end

  def snapshot(dest_rv, snapshotted = nil)
    snapshotted ||= self.carbon_copy.content.dup
    self.revisions.all({ :order => [ :created_at.desc ] }).each { |rv|
      break if rv == dest_rv
      snapshotted = rv.apply(snapshotted)
    }
    snapshotted
  end

  # Replaces the content of the carbon copy and the page with
  # the snapshot taken from the specified revision. All revisions
  # created after the specified one will be destroyed.
  def rollback(dest_rv)
    new_content     = snapshot(dest_rv)
    current_content = self.content.dup

    unless carbon_copy.update!({ content: new_content })
      return false
    end

    unless update!({ content: new_content })
      carbon_copy.update!({ content: current_content })
      return false
    end

    unless revisions.all({ :created_at.gt => dest_rv.created_at }).destroy
      update!({ content: current_content })
      carbon_copy.update!({ content: current_content })
      return false
    end

    current_content = nil

    true
  end

  def url(root = false)
    root ? "/pages/#{id}" : "#{space.url(true)}/pages/#{id}"
  end

  def href
    "#{folder.href}/#{pretty_title}"
  end

  def revisions_url
    self.url(true) + '/revisions'
  end

  def editable_by?(user)
    folder.space.editor?(user)
  end

  def is_homepage?
    [ 'README', 'Home' ].include?(self.title)
  end

  def self.random_suffix
    Base64.urlsafe_encode64(Random.rand(12345 * 100).to_s)
  end

  def serialize(with_content = false)
    s = { id: id, title: title, folder: folder_id || 0, nr_revisions: revisions.count }
    s.merge!({ content: content }) if with_content
    s
  end

  def to_json(*args)
    serialize(args).to_json
  end

  def space
    folder.space
  end

  private

  # pre-destroy validation hook:
  #
  # Pages are deletable only by their authors.
  # def deletable_by?(context = :default)
  #   errors.delete(:creator)

  #   if !editor
  #     errors.add :creator, "An editor must be assigned before attempting to remove a page."
  #   elsif creator.id != editor.id
  #     errors.add :creator, "Pages can be deleted only by their author."
  #   end

  #   throw :halt unless errors.empty?

  #   errors.empty?
  # end
end