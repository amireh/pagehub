module TableOfContents

  # Builds a tree of headings from a given block of Markdown
  # text, the returned list can be turned into HTML using
  # TableOfContents::to_html()
  def self.from_markdown(markdown, threshold = 6)
    self.from_content(/(#+)\s([^\n]+)/, lambda { |l, t| return l.length, t }, markdown, threshold)
  end

  # Builds a tree of headings from a given block of HTML,
  # the returned list can be turned into an HTML list using
  # TableOfContents::to_html()
  # def self.from_html(html, threshold = 6)
  #   self.from_content(/<h([1-6]).*>(.*)<\/h\1>/, lambda { |l,t| return l.to_i, t }, html, threshold)
  # end

  def self.from_content(pattern, formatter, content, threshold)
    headings  = []
    current   = []
    toc_index = 0
    content.scan(pattern).each { |l, t|
      level,title = formatter.call(l, t)

      if level <= threshold 
        h = Heading.new(title, level, toc_index)
        headings << h
        current[level] = h
        toc_index += 1 # toc_index is used for hyperlinking

        # if there's a parent, attach this heading as a child to it
        if current[level-1] then
          current[level-1] << h
        end
      end
    }

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
    toc.each { |heading| html << heading.to_html }
    html << "</ol>"
    html
  end

  private

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

    def to_html()
      html = ""
      html << "<li>"
      html << "<a href=\"\#toc_#{self.index}\">" << self.title << "</a>"

      if self.children then
        html << "<ol>"
        self.children.each { |child| html << child.to_html }
        html << "</ol>"
      end

      html << "</li>"
    end
  end
end

PageHub::Markdown::add_processor :pre_render, lambda { |str|
  str.gsub!(/^\B\[\!toc(.*)\!\]/) {
    TableOfContents.to_html TableOfContents.from_markdown(str, $1.empty? ? 6 : $1.strip.to_i)
  }
  str
}