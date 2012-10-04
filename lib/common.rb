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

  def is_email?
    (self =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/u) != nil
  end

  def to_markdown
    PageHub::Markdown.render!(self)
  end

  def minify(type = :css)
    case type
    when :css
      self.gsub(/(;\s+)/, ';').gsub(/\n+\s*/, '').gsub(/\s+\{\s*/, '{').gsub(/\s+\}/, '}')
    end
  end
end

module Sinatra

  class Base
    class << self

      # for every DELETE route defined, a "legacy" GET equivalent route is defined
      # at @{path}/destroy for compatibility with browsers that do  not support
      # XMLHttpRequest and thus the DELETE HTTP method
      def delete(path, opts={}, &bk)
        route 'GET'   , "#{path}/destroy",  opts, &bk
        route 'DELETE', path,               opts, &bk
      end

    end
  end

  private

  module Templates
    private
      MDBTag = '<markdown>'
      MDETag = '</markdown>'
    public

    def erb(template, options={}, locals={})
      mixed = render :erb, template.to_sym, { layout: @layout }.merge(options), locals

      if template.to_s.include?('.md')
        b = mixed.index(MDBTag)
        while b && b >= 0
          # locate the enclosing tag position
          e = mixed.index(MDETag, b)

          if e.nil?
            raise RuntimeError.new(
              "Missing enclosing </markdown> tag in #{template.to_s}" +
              " for the Markdown block beginning at #{b}")
          end

          # capture the block from b+'<markdown>'.length to e-1
          puts "Found a Markdown block @ #{b}-#{e}:"
          block_boundaries = b..e+MDETag.length-1
          md_block = mixed[b+MDBTag.length..e-1]
          md_block = md_block.lines.map { |l| l.gsub(/^[ ]+/, '') }.join

          # render the markdown block and replace it with the raw one
          mixed[block_boundaries] = md_block.to_markdown

          # locate the next <markdown> block, if any
          b = mixed.index(MDBTag)
        end
      end

      mixed
    end

    def partial(template, options={}, locals={})
      erb template.to_sym, options.merge({ layout: false }), locals
    end
  end

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