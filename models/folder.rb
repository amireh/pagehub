# Folders are a grouping of pages and folders.
class Folder < PageHub::Resource

  has n, :pages, :constraint => :set_nil
  has n, :groups, :through => DataMapper::Resource
  belongs_to :folder, default: nil, required: false

  def serialize(*args)
    pages = []
    self.pages.each { |p|
      pages << { title: p.title, id: p.id }
    }
    { id: id, parent: folder_id, title: title, pages: pages }
  end
  
  def to_json(*args)
    serialize.to_json
  end

  def child_folders(all_folders = [])
    all_folders = []
    self.folders.each { ||}
  end

  def is_child_of?(in_folder)
    if self.folder then
      return self.folder == in_folder ? true : self.folder.is_child_of?(in_folder)
    end

    false
  end
  
end