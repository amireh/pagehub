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

module PageHub
  module Markdown

    Stages = [ :pre_render, :post_render ]
    @@hooks = { }
    @@mutators = []

    class Processor
      def initialize(stage)
        Markdown::add_processor(stage, self)
        super()
      end

      def consume(str, stage)
        str
      end
    end

    class << self
      def add_processor(stage, p)
        Stages.each { |s| @@hooks[s] ||= [] }

        unless Stages.include?(stage.to_sym)
          err = "Invalid Markdown Processor stage #{stage}. Allowed stages are :pre_render and :post_render"
          raise RuntimeError.new err
        end

        if stage.is_a? String
          @@hooks[stage.to_sym] << p
        elsif stage.is_a? Symbol
          @@hooks[stage] << p
        elsif stage.is_a? Array
          stage.each { |s| @@hooks[s] << p }
        end
      end

      def add_mutator(m)
        @@mutators << m
      end

      def render(str)
        @@hooks[:pre_render].each { |processor| processor.call(str) }

        # escape any JavaScript snippets
        str.gsub!(/\<script(.*)\>/i) {
          mutated = true
          
          "&lt;script#{$1}&gt;"
        }

        # Render the Markdown as HTML
        # markdown = Redcarpet::Markdown.new(HTMLwithAlbino.new({ :with_toc_data => true }), RendererOptions)
        str = @@renderer.render(str)

        @@hooks[:post_render].each { |processor| processor.call(str) }

        str
      end

      def mutate!(str)
        mutated = false
        @@mutators.each { |m| mutated ||= m.call(str) }
        mutated
      end

    end

    private

    RendererOptions = {
      autolink: true,
      space_after_headers: true,
      fenced_code_blocks: true,
      no_intra_emphasis: true
    }

    @@renderer = Redcarpet::Markdown.new(HTMLwithAlbino.new({ :with_toc_data => true }), RendererOptions)
  end
end