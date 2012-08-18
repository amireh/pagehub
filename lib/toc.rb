require 'json'

module TableOfContents

  # Builds a tree of headings from a given block of Markdown
  # text, the returned list can be turned into HTML using
  # TableOfContents::to_html()
  #
  def self.from_markdown(markdown)
    pat       = /(\#+)\s(.*)\n/
    index     = markdown.index(pat)
    headings  = []
    current   = []
    count     = 0

    while !index.nil? && index >= 0
      level = $1.length
      title = $2
      
      h = Heading.new(title, level, count)
      headings << h
      current[level] = h
      count += 1 # count is used for anchor generation

      # if there's a parent, attach this heading as a child to it
      if current[level-1] then
        current[level-1] << h
      end

      # puts "##{index}:\t#{level} => #{title}"

      index = markdown.index(/(\#+)\s(.*)\n/, index+title.length)
    end

    toc = []
    headings.each { |h|
      next if h.parent
      toc << h
    }

    toc
  end

  # Renders a table of content using nested <ol> list nodes
  # from a given list of Heading objects produced by 
  # TableOfContents::from_markdown()
  #
  def self.to_html(toc)
    html = "<ol>"
    toc.each { |heading|
      html << heading.to_html
    }
    html << "</ol>"
    html
  end

  class Heading
    attr_accessor :level, :title, :children, :parent, :index
    
    def initialize(title, level, index)
      @title = title
      @level = level
      @index = index
      @parent = nil
      @children = []
      super()
    end

    def <<(h)
      @children.each { |child|
        return if child.title == h.title
      }

      h.parent = self
      @children << h
    end

    def to_json(s = nil)
      "{ #{title.to_json}: #{children.to_json} }"
    end

    def to_html()
      html = ""
      html << "<li>"
      html << "<a href=\"\#toc_#{self.index}\">" << self.title << "</a>"

      if self.children then
        html << "<ol>"
        
        self.children.each { |child|
          html << child.to_html
        }

        html << "</ol>"
      end

      html << "</li>"
    end
  end
end
