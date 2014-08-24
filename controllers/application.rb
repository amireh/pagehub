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
  @layout = logged_in? ?
            :"layouts/primary" :
            :"layouts/guest"
  @print  = :"layouts/print"
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

get '/explore*' do |domain|
  unless [ '', 'spaces', 'browser', 'interface', 'workspace' ].include?(domain)
    pass
  end

  erb :"explore/index"
end

post '/markdown/raw', provides: [ :text ] do
  md, content = nil, request.body.read

  if content.nil? || content.empty?
    halt 400, "Missing Markdown content."
  end

  begin
    md = content.to_markdown
  rescue Exception => e
    halt 400, e.message
  end

  respond_to do |f|
    f.text { md }
  end
end

if settings.development? && !ENV['OPTIMIZED']
  get '/public/js/compiled/app.js' do
    File.read(settings.root + '/app/assets/javascripts/main.js')
  end
end

user do current_user end