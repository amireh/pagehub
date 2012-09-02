require 'open-uri'
require 'net/http'

# Downloads remote textual resources from websites
# and allows for content extraction from HTML pages
# so it can be neatly embedded in another page.
module Embedder

  # Resources whose content-type is not specified in this
  # list will be rejected
  AllowedTypes = ["text/plain", /text\/html/, "application/html"]

  # Resources larger than 1 MByte will be rejected
  MaximumLength = 1 * 1024 * 1024

  # Resources served by any of the hosts specified in this list 
  # will be rejected
  FilteredHosts = []

  @@processors = []

  class EmbeddingError < RuntimeError; end
  class InvalidSizeError < EmbeddingError; end
  class InvalidTypeError < EmbeddingError; end

  class << self

    # Performs a HEAD request to validate the resource, and if it
    # passes the checks it will be downloaded and processed if
    # any eligible Embedder::Processor is registered.
    #
    # Arguments:
    # => raw_uri  the full raw URI of the file to be embedded
    # => source   an optional identifier to specify the Processor
    #             that should be used to post-process the content
    # => args     options that can be meaningful to the Processor, if any
    #
    # Returns:
    # => A string containing the extracted data, or an empty one
    def get_resource(raw_uri, source = "", args = "")
      begin
        uri = URI.parse(raw_uri)

        # reject if the host is banned
        return "" if FilteredHosts.include?(uri.host)

        Net::HTTP.start(uri.host, uri.port) do |http| 
          http.open_timeout = 2
          http.read_timeout = 2

          # get the content type and length
          ctype = ""
          clength = 0
          http.head(uri.path).each { |k,v|
            # puts "#{k} => #{v}"
            ctype = v if k == "content-type"
            clength = v.to_i if k == "content-length"
          }

          raise InvalidTypeError.new ctype if !self.allowed?(ctype)
          raise InvalidSizeError.new clength if clength > MaximumLength

          open(raw_uri) { |f| 
            content = f.read

            # invoke processors
            keys = []
            keys << source unless source.empty?
            keys << raw_uri
            @@processors.each { |p|
              if p.applies_to?(keys) then
                content = p.process(content, args)
                break
              end
            }

            return content
          }
        end
      rescue EmbeddingError => e
        # we want to escalate these errors
        raise e
      rescue Exception => e
        # mask as a generic EmbeddingError
        raise EmbeddingError.new e.message
      end

      ""
    end

    def allowed?(ctype)
      AllowedTypes.each { |t|
        return true if t.match ctype
      }
      false
    end

    def register_processor(proc)
      @@processors ||= []
      @@processors << proc
    end

  end # class << self

  class Processor

    # Processors apply to "keys" which can be written manually
    # in Markdown by the user, or are found in the host portion
    # of the resource URI
    #
    # IE, a Github Wiki processor would bind to the keys:
    # => "github-wiki", or/and /github.com.*\/wiki\//
    #
    # Manual keys are injected after the !include keyword:
    # [!include github-wiki!](https://github.com/some-dude/wiki/Home)
    #
    def initialize(keys)
      @keys = keys
      super()
    end

    def process(content, args = "")
      content
    end

    def applies_to?(keys)
      @keys.each { |h| keys.each { |k| return true if h.match k } }
      false
    end
  end

  # Extracts content from GitHub Wiki pages
  #
  # Bound keys:
  # => "github-wiki"
  # => URI("[...]github.com/[...]/wiki/[...]")
  #
  class GithubWikiProcessor < Processor
    def initialize()
      super(["github-wiki", /github.com.*\/wiki\//])
    end

    # Returns the content of the node <div class='markdown-body'></div>,
    # it will also remove all id attributes of all content nodes.
    #
    # Supported options:
    # 1. "reduce-headings": all heading nodes (<h1> through <h5>) will be
    #                       stepped one level, so h1 becomes h2, etc.
    def process(content, args = "")
      html_doc = Nokogiri::HTML(content) do |config| config.noerror end
      html_doc.xpath("//*[@id]").each { |node| node.remove_attribute "id" }
      node = html_doc.xpath("//div[@class='markdown-body']")

      if args.include?("reduce-headings") then
        5.downto(1) { |level|
          node.xpath("//h#{level}").each { |heading_node|
            heading_node.name = "h#{level+1}"
          }
        }
      end

      node
    end

  end

  # Extracts content from PageHub shared documents
  #
  # Bound keys:
  # => "pagehub"
  # => URI([...]pagehub.mxvt.net/[...])
  class PageHubProcessor < Processor
    def initialize()
      super(["pagehub", /pagehub.mxvt.net/])
    end

    def process(content, args = "")
      html_doc = Nokogiri::HTML(content) do |config| config.noerror end
      node = html_doc.xpath("//div[@id='content']")
      html_doc.xpath("//*[@id]").each { |node| node.remove_attribute "id" }
      node
    end
  end

  register_processor(GithubWikiProcessor.new)
  register_processor(PageHubProcessor.new)
end

PageHub::Markdown::add_processor :pre_render, lambda {|str|
  # Embed remote references, if any
  str.gsub!(/^\B\[\!include\s?(.*)\!\]\((.*)\)/) { 
    content = ""
    
    uri = $2

    # parse the content source and args, if any
    source = ($1 || "").split.first || ""
    args = ($1 || "").split || []
    args = args[1..args.length].join(' ') unless args.empty? 

    begin
      content = Embedder.get_resource(uri, source, args)
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

  str  
}