class Page < PageHub::Resource

  property :content, Text, default: "This page is empty!"

  belongs_to :folder, required: false, default: nil
  has n, :groups, :through => DataMapper::Resource

  def group_names()
    groups = []; self.groups.each { |g| groups << g.name }; groups
  end

  def serialize_groups
    groups = []; self.groups.each { |g| groups << { id: g.id } }; groups
  end

  def serialize
    super().merge({ folder: folder_id, user: user.id})
  end

end