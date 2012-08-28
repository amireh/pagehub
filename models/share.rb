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

# class Share
#   include DataMapper::Resource

#   property :id, Serial
  
#   belongs_to :user
#   property :permissions, Flag [ :read, :write, :append ]
#   property :created_at,     DateTime, default: lambda { |*_| DateTime.now }
# end