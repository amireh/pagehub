object @folder

attributes :id, :title, :browsable

child(:space) do |f|
  attributes :id
end

child(:folder => :folder) do |f|
  attributes :id
end

node(:folders) { |f|
  f.folders.map { |f|
    { id: f.id, title: f.title }
  }
}

node(:pages) { |f|
  f.pages.map { |p|
    { id: p.id, title: p.title }
  }
}
