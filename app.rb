$ROOT = File.dirname(__FILE__)
$LOAD_PATH << $ROOT

gem 'sinatra'
gem 'sinatra-content-for'
gem 'sinatra-flash'
gem "data_mapper", ">=1.2.0"
gem 'redcarpet'
gem 'albino'

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/flash'
require 'data_mapper'
require 'dm-mysql-adapter'
require "digest/sha1"
require 'redcarpet'
require 'json'
require 'albino'
require 'open-uri'

def get_remote_resource(uri)
  begin
    return open(uri).string
  rescue Exception => e
    puts e
    return ""
  end
end

class HTMLwithAlbino < Redcarpet::Render::HTML
  def block_code(code, language)
    begin
      return Albino.colorize(code, language)
    rescue
      return "-- INVALID CODE BLOCK, MAKE SURE YOU'VE SURROUNDED CODE WITH ``` --"
    end
  end
end

class String
  def sanitize
    self.downcase.gsub(/\W/,'-').squeeze('-').chomp('-')
  end

  def to_markdown

    self.gsub!(/\[\!include\!\]\((.*)\)/) { 
      get_remote_resource($1)
    }

    markdown_opts = {
      autolink: true,
      space_after_headers: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true
    }

    markdown = Redcarpet::Markdown.new(HTMLwithAlbino, markdown_opts)
    # markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, markdown_opts)
    markdown.render(self)
  end
end

module Preferences
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

configure do
  # enable :sessions
  use Rack::Session::Cookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'

  def load(directory)
    Dir.glob("#{directory}/*.rb").each { |f| require f }
  end

  # DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, 'mysql://root:mysqlZephyr771@localhost/naughty')

  load "models"
  load "controllers"

  DataMapper.finalize
  DataMapper.auto_upgrade!

  set :default_preferences, JSON.parse(File.read("default_preferences.json"))
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
