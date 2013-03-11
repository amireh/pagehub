ReservedResourceTitles = %w(
  edit settings
)
ReservedSpaceTitles = %w(
  dashboard
  spaces
  settings
)

ReservedUsernames = %w[
  pagehub
  names name
  spaces space
  pages page
  users user demo
  organizations organization
  groups group
  spec
  explore search features blog plans interface
  site about open-source faq tos service terms security
  sessions session
  signup
  new
  login logout
  stars favorites
  edu
  help
]

puts ReservedResourceTitles.inspect

def reserved?(name)
  ReservedNames.include?(name)
end

def resource_title_available?(title)
  pretty = (title || '').to_s.sanitize
  !pretty.empty? && pretty.length >= 3 && !ReservedResourceTitles.include?(pretty)
end

def name_available?(name)
  nn = (name || '').to_s.sanitize
  !nn.empty? &&
  nn.length >= 3 &&
  !ReservedSpaceTitles.include?(nn) &&
  current_user.owned_spaces.first({ pretty_title: nn }).nil?
end

def nickname_available?(name)
  nn = (name || '').to_s.sanitize
  !nn.empty? &&
  nn.length >= 3 &&
  !ReservedUsernames.include?(nn) &&
  User.first({ nickname: nn }).nil?
end

before do
  if api_call?
    # puts "its an api call"
    # puts request.content_type
    request.body.rewind
    body = request.body.read.to_s || ''
    unless body.empty?
      begin;
        params.merge!(JSON.parse(body))
        # puts params.inspect
        # puts request.path
      rescue JSON::ParserError => e
        puts e.message
        puts e.backtrace
      end
    end
  else
    @layout = "layouts/#{logged_in? ? 'primary' : 'guest' }".to_sym
  end
end

get '/' do
  pass unless logged_in?

  redirect current_user.dashboard_url
end

get '/' do
  erb :"static/greeting.md"
end

get "/users/:user_id/spaces/:space_id/testdrive",
  auth: [ :user ],
  provides: [ :html ],
  requires: [ :user, :space ] do

  erb :"static/tutorial.md", layout: :"layouts/print"
end

[ 'features', 'about', 'open-source', 'interface' ].each do |static_view|
  get "/#{static_view}" do
    erb :"static/#{static_view}.md"
  end
end

user do current_user end