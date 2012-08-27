require 'redcarpet'
require 'albino'

# a renderer that uses Albino to highlight syntax
class HTMLwithAlbino < Redcarpet::Render::HTML
  def block_code(code, language)
    begin
      return Albino.colorize(code, language)
    rescue
      return "-- INVALID CODE BLOCK, MAKE SURE YOU'VE SURROUNDED CODE WITH ``` --\n\n#{code}"
    end
  end
end

class String
  def sanitize
    self.downcase.gsub(/\W/,'-').squeeze('-').chomp('-')
  end

  def to_markdown

    # Embed remote references, if any
    has_embedded_html = false
    self.gsub!(/^\B\[\!include\s?(.*)\!\]\((.*)\)/) { 
      content = ""
      
      uri = $2

      # parse the content source and args, if any
      source = ($1 || "").split.first || ""
      args = ($1 || "").split || []
      args = args[1..args.length].join(' ') unless args.empty? 

      begin
        content = Embedder.get_resource(uri, source, args)
        has_embedded_html = true
      rescue Embedder::InvalidSizeError => e
        content << "**Embedding error**: the file you tried to embed is too big - #{e.message.to_i} bytes."
        content << " (**Source**: [#{$2}](#{$2}))\n\n"
      rescue Embedder::InvalidTypeError => e
        content << "**Embedding error**: the file type you tried to embed (`#{e.message}`) is not supported."
        content << " (**Source**: [#{$2}](#{$2}))\n\n"
      rescue Embedder::EmbeddingError => e
        content << "**Embedding error**: #{e.message}."
        content << " (**Source**: [#{$2}](#{$2}))\n\n"
      end

      # content = "<div data-embedded=true>#{content.to_s.to_markdown}</div>".to_markdown
      # content = "#{content}"
      content
    }

    # Build ToC from Markdown
    # unless has_embedded_html then
      self.gsub!(/^\B\[\!toc(.*)\!\]/) {
        TableOfContents.to_html TableOfContents.from_markdown(self, $1.empty? ? 6 : $1.strip.to_i)
      }
    # end

    self.gsub!(/\<script(.*)\>/i) {
      "&lt;script#{$1}&gt;"
    }

    # Render the Markdown as HTML
    markdown_opts = {
      autolink: true,
      space_after_headers: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true
    }
    markdown = Redcarpet::Markdown.new(HTMLwithAlbino.new({ :with_toc_data => true }), markdown_opts)
    markdown.render(self)

    # Build ToC from the rendered HTML, if extra content was embedded
    # if has_embedded_html then
      # html = TableOfContents.repair_links(html)
      # html.gsub!(/\[\!toc(.*)\!\]/) {
      #   TableOfContents.to_html TableOfContents.from_html(html, $1.empty? ? 6 : $1.strip.to_i)
      # }
    # end

    # html
  end
end