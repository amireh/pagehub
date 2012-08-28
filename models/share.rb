# Shares occur between a user and a target on a resource:
# => target   can be a user or a group
# => resource can be a page or a folder
#
# Shares have permissions:
# => 1. read permission (by default)
# => 2. write permission (explicitly grantable)
# => 3. append permission (folder-share only)
#
# Regardless of the granted permissions, a resource can only
# be renamed and removed by its author.
#
# Shares callbacks:
# => notification when a share is revoked

class Share
  include DataMapper::Resource

  property :id, Serial
  property :permissions, Flag[ :read, :write, :append ], default: :read
  property :created_at,     DateTime, default: lambda { |*_| DateTime.now }
  
  belongs_to :user, required: false
  belongs_to :group, required: false
  belongs_to :resource, PageHub::Resource
  # has 1, :user, :through => :resource, :as => :source
  # has 1, :share_target

  def target
    user || group
  end

  def group_share?
    !group.nil?
  end

  def user_share?
    !user.nil?
  end

  def public_share?
    !user && !group
  end
end