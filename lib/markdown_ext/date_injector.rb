PageHub::Markdown.add_mutator lambda { |str|
  mutated = false
  str.gsub!(/\[\!date(.*)\!\]/) {
    mutated = true

    format = $1.empty? ? "%D" : $1.strip
    DateTime.now.strftime(format)
  }

  mutated
}