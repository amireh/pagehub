class CarbonCopy
  include DataMapper::Resource

  property :content, Text, default: ""
  belongs_to :page, key: true
end