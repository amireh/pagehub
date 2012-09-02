# encoding: UTF-8

require 'addressable/uri'

class Hash
  # Removes a key from the hash and returns the hash
  def delete!(key)
    self.delete(key)
    self
  end
end

class String
  def sanitize
    Addressable::URI.
      parse(self.
            downcase.
            gsub(/[[:^word:]]/u,'-').
            squeeze('-').chomp('-')
      ).normalized_path
  end

  def to_markdown
    PageHub::Markdown.render(self)
  end
end