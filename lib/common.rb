# encoding: UTF-8

require 'addressable/uri'

class Hash
  # Removes a key from the hash and returns the hash
  def delete!(key)
    self.delete(key)
    self
  end

  # Merges self with another hash, recursively.
  #
  # This code was lovingly stolen from some random gem:
  # http://gemjack.com/gems/tartan-0.1.1/classes/Hash.html
  #
  # Thanks to whoever made it.
  def deep_merge(hash)
    target = dup

    hash.keys.each do |key|
      if hash[key].is_a? Hash and self[key].is_a? Hash
        target[key] = target[key].deep_merge(hash[key])
        next
      end

      target[key] = hash[key]
    end

    target
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

module Sinatra
  module ContentFor
    def yield_with_default(key, &default)
      unless default
        raise RuntimeError.new "Missing required default block"
      end

      if !content_for?(key)
        content_for(key.to_sym, &default)
      end

      yield_content(key)
    end

    def content_for?(key)
      content_blocks[key.to_sym].any?
    end
  end
end