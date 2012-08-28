class Page < PageHub::Resource

  property :content, Text, default: "This page is empty!"

  belongs_to :folder, required: false
  has n, :groups, :through => DataMapper::Resource

  def group_names()
    groups = []; self.groups.each { |g| groups << g.name }; groups
  end

  def serialize_groups
    groups = []; self.groups.each { |g| groups << { id: g.id } }; groups
  end

  def serialize
    { id: id, title: title, folder: folder_id || 0, user: user_id, groups: serialize_groups }
  end

  def to_json(*args)
    serialize.to_json
  end

end