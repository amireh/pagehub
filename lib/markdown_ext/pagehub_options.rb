PageHub::Markdown.add_processor :post_render, lambda { |str|
  str.gsub!(/\[\!options(.*)\!\]/) {
    opts = $1
    out = ""

    unless opts.empty?
      opts = opts.split(' ').each { |opt|
        case opt
        when "no-title"
          out += "<style>header h1 { display: none }</style>"
        end
      }
    end

    out
  }
}