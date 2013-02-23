module Sinatra
  class Base
    class << self
      def get(path, opts={}, &block)
        # puts "GET: #{path}"

        # conditions = @conditions.dup
        route('GET', path, opts, &block)

        # @conditions = conditions
        route('HEAD', path, opts, &block)
      end

      # for every DELETE route defined, a "legacy" GET equivalent route is defined
      # at @{path}/destroy for compatibility with browsers that do  not support
      # XMLHttpRequest and thus the DELETE HTTP method
      def delete(path, opts={}, &bk)
        route 'GET'   , "#{path}/destroy",  opts, &bk
        route 'DELETE', path,               opts, &bk
      end
      
      # for every DELETE route defined, a "legacy" GET equivalent route is defined
      # at @{path}/destroy for compatibility with browsers that do  not support
      # XMLHttpRequest and thus the DELETE HTTP method
      def put(path, opts={}, &bk)
        route 'put', path,               opts, &bk
        route 'PATCH', path,               opts, &bk
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
          block_boundaries = b..e+MDETag.length-1
          md_block = mixed[b+MDBTag.length..e-1]
          md_block = md_block.lines.map { |l| l.gsub(/^[ ]+/, '') }.join

          # render the markdown block and replace it with the raw one
          mixed[block_boundaries] = md_block.to_markdown

          # locate the next <markdown> block, if any
          b = mixed.index(MDBTag)
        end
      end

      mixed.force_encoding('UTF-8')
    end

    def partial(template, options={}, locals={})
      erb template.to_sym, options.merge({ layout: false }), locals
    end
    
  end # Base
end # Sinatra