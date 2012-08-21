class PageHub < Sinatra::Base
  helpers do
    module Preferences
      # mapping of displayable font names to actual CSS font-family names
      FontMap = { 
        "Proxima Nova" => "ProximaNova-Light",
        "Ubuntu" => "UbuntuRegular",
        "Ubuntu Mono" => "UbuntuMonoRegular",
        "Monospace" => "monospace, Courier New, courier, Mono",
        "Arial" => "Arial",
        "Verdana" => "Verdana",
        "Helvetica Neue" => "Helvetica Neue"
      }
    end
  end

  configure do
    helpers Sinatra::ContentFor
    register Sinatra::Flash

    # DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, 'mysql://root@localhost/notebook')

    # load the models and controllers
    ["models", "controllers"].each { |resources|
      Dir.glob("#{resources}/*.rb").each { |f| require f }
    }
    
    require 'lib/session'

    DataMapper.finalize
    DataMapper.auto_upgrade!

    set :default_preferences, JSON.parse(File.read(File.join($ROOT, "default_preferences.json")))
    set :public_folder, File.join($ROOT, "public")
    set :views, File.join($ROOT, "views")
  end

  before do
    # CodeMirror theme
    @theme = @cm_theme = "neat"
  end

  get '/' do
    destination = "greeting"

    if logged_in?
      @pages = Page.all(user_id: current_user.id)
      destination = "index"
    end

    erb destination.to_sym
  end

  get '/tutorial' do
    erb :"/tutorial.md", layout: :"print_layout"
  end

  get '/markdown-cheatsheet' do
    erb :"/markdown-cheatsheet", layout: :"print_layout"
  end

  get '/testdrive' do
    erb :"/tutorial.md", layout: :"print_layout"
  end

  # not_found do
  #   erb :"404"
  # end

  error 403 do
    erb :"403"
  end
end