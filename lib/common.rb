require 'redcarpet'
require 'albino'
require 'open-uri'

# downloads a remote resource
def get_remote_resource(uri)
  begin
    return open(uri).string
  rescue Exception => e
    puts e
    return ""
  end
end

# a renderer that uses Albino to highlight syntax
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

    # Expand remote references, if any
    self.gsub!(/\[\!include\!\]\((.*)\)/) { 
      get_remote_resource($1)
    }

    # Create a ToC if invoked
    self.gsub!(/\[\!toc\!\]/) {
      TableOfContents.to_html TableOfContents.from_markdown(self)
    }

    markdown_opts = {
      autolink: true,
      space_after_headers: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true
    }

    markdown = Redcarpet::Markdown.new(HTMLwithAlbino.new({ :with_toc_data => true }), markdown_opts)
    markdown.render(self)
  end
end

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