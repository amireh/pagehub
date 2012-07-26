class Tag
  include DataMapper::Resource

  property :id, Serial
  property :label, String, required: true

  has n, :pages, :through => Resource
end