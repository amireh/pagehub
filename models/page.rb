require 'digest/sha1'
require 'base64'

class Page
  include DataMapper::Resource

  attr_writer :operating_user

  property :id,           Serial
  property :title,        String, length: 120, default: lambda { |r, _| "Untitled ##{Page.random_suffix}" }
  property :pretty_title, String, length: 120, default: lambda { |r, _| r.title.sanitize }
  property :content,      Text,   default: ""
  property :created_at,   DateTime, default: lambda { |*_| DateTime.now }

  belongs_to :user
  belongs_to :folder, default: nil, required: false
  belongs_to :group,  default: nil, required: false
  has n, :public_pages, :constraint => :destroy
  has n, :revisions, :constraint => :destroy
  has 1, :carbon_copy, :constraint => :destroy

  validates_presence_of :title
  validates_length_of   :title, :within => 3..120

  before :valid? do
    self.pretty_title = self.title.sanitize
  end

  # [ :update, :save ].each { |advice|
  #   before advice do |context|
  #   end
  # }

  after :create, :init_cc
  before :valid?, :init_cc

  def init_cc(context = nil)
    # Don't initialize the CC with our content because
    # we want the first revision to reflect the entire
    # changes the post was first created with.
    if !self.carbon_copy
      self.carbon_copy = CarbonCopy.new
      self.carbon_copy.page = self
      self.carbon_copy.save! # make sure to use the bang version here
    end
  end

  before :destroy, :deletable_by?

  def generate_revision(new_content, editor)
    if !persisted?
      errors.add :revisions, "Page revisions can not be generated from new pages."
      return false
    end

    if !new_content
      return true
    end

    rv = Revision.new
    rv.context = { content: new_content }
    rv.editor = editor
    rv.page = self # doing otherwise will make the page dirty
    unless rv.save
      errors.add :revisions, "Unable to generate revision: #{rv.collect_errors}"
      rv = nil
      return false
    end

    carbon_copy.update({ content: new_content })

    true
  end

  def snapshot(dest_rv, snapshotted = nil)
    snapshotted ||= carbon_copy.content.dup
    revisions.all({ :order => [ :created_at.desc ] }).each { |rv|
      break if rv == dest_rv
      snapshotted = rv.apply(snapshotted)
      # snapshotted = Diff::LCS.unpatch!(snapshotted.split("\n"), Marshal.load(rv.blob)).join("\n")
    }
    snapshotted
  end

  # Replaces the content of the carbon copy and the page with
  # the snapshot taken from the specified revision. All revisions
  # created after the specified one will be destroyed.
  def rollback(dest_rv)
    new_content = snapshot(dest_rv)
    current_content = self.content.dup

    unless carbon_copy.update({ content: new_content })
      return false
    end

    unless update({ content: new_content })
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

  def compound_url
    f = folder
    ancestry = []
    while f
      ancestry.insert(0,f.pretty_title)
      f = f.folder
    end

    ancestry << pretty_title
    ancestry.join('/')
  end

  def editable_by?(u = nil)
    u ||= current_user
    self.user == u || self.group && self.group.has_editor?(u)
  end

  def public_url(relative = false)
    prefix = relative ? "" : "http://www.pagehub.org"
    "#{prefix}/#{self.user.nickname}/#{self.pretty_title}"
  end

  def revisions_url(prefix = "")
    "#{prefix}/pages/#{self.id}/revisions"
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

  private

  # pre-destroy validation hook:
  #
  # Pages are deletable only by their authors.
  def deletable_by?(context = :default)
    if user != @operating_user
      errors.add :_, "Pages can be deleted only by their author."
    end

    throw :halt unless errors.empty?
  end
end