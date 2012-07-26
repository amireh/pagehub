# class Notebook
#   include DataMapper::Resource

#   property :id, Serial
#   property :label, String, default: "Untitled"
#   property :created_at, DateTime, default: lambda { |*_| DateTime.now }

#   has n, :pages
#   belongs_to :user
# end