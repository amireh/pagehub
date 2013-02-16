object @folder

attributes :id, :title, :browsable

child(:space) do |f|
  attributes :id
end

child(:folder => :folder) do |f|
  attributes :id
end

node(:folders) { |f|
  f.folders.map { |cf|
    partial("folders/_show", object: cf)
  }
}

node(:pages) { |f|
  f.pages.collect { |p|
    partial("pages/_show", object: p)
  }
}
