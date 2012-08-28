# Folders are a grouping of pages and folders.
class Folder < PageHub::Resource

  has n, :pages,  :constraint => :set_nil
  has n, :groups, :through => DataMapper::Resource

  belongs_to :folder, default: nil, required: false

  def serialize(*args)
    pages = []
    self.pages.each { |p|
      pages << { title: p.title, id: p.id }
    }
    super().merge({ parent: folder_id, pages: pages })
  end
  
  def is_child_of?(in_folder)
    if self.folder then
      return self.folder == in_folder ? true : self.folder.is_child_of?(in_folder)
    end

    false
  end

  def folders
    self.user.folders({ folder_id: self.id, :id.not => self.id })
  end  
end