helpers do
  def traverse_space(space, handlers, cnd = {}, coll = nil)
    raise InvalidArgumentError unless handlers[:on_page] && handlers[:on_page].respond_to?(:call)
    raise InvalidArgumentError unless handlers[:on_folder] && handlers[:on_folder].respond_to?(:call)

    dump_pages = nil
    dump_pages = lambda { |coll|
      coll.each { |p| handlers[:on_page].call(p) }
    }

    unless coll
      dump_pages.call(@space.pages.all({ conditions: cnd.merge({ folder_id: nil }), order: [ :title.asc ] }))
    end

    dump_folder = nil
    dump_folder = lambda { |f|
      handlers[:on_folder].call(f)
      dump_pages.call(f.pages.all({ conditions: cnd, order: [ :title.asc ]} ))
      f.folders.all({ conditions: cnd }).each { |cf| dump_folder.call(cf) }
      handlers[:on_folder_done].call(f) if handlers[:on_folder_done]
    }

    (coll || @space.folders.all({ conditions: cnd.merge({ folder_id: nil }), order: [ :title.asc ] })).each { |f| dump_folder.call(f) }
  end

  # fully qualified space title
  def fq_space_title(s)
    s.creator.nickname + '/' + '<strong>' + s.title + '</strong>'
  end
end