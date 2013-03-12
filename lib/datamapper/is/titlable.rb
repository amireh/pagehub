require 'dm-core'
require 'dm-types'

module DataMapper
  module Is
    module Titlable

      def is_titlable(options = {})
        extend  ClassMethods
        include InstanceMethods

        options = {
          property: :title,
          sanitizer: 'pretty',
          default: '',
          length:  120,
          messages: {
            presence: 'A title must be provided.',
            length:   'Title must be at least 3 characters long.'
          }
        }.deep_merge(options)

        base_prop = options[:property].to_sym
        sane_prop = (options[:sanitizer] + '_' + base_prop.to_s).to_sym

        property base_prop, DataMapper::Property::String, length: options[:length], default: options[:default]
        property sane_prop, DataMapper::Property::String, length: options[:length]

        validates_presence_of base_prop, message: options[:messages][:presence]
        validates_length_of   base_prop, within: 3..120, message: options[:messages][:length]

        @__title_base_prop = base_prop
        @__title_sane_prop = sane_prop

        before :valid?, :build_sane_title_if_applicable
      end

      module ClassMethods
        attr_reader :__title_base_prop, :__title_sane_prop
      end

      module InstanceMethods
        def build_sane_title_if_applicable(*ctx)
          if attribute_dirty?(model.__title_base_prop)
            self.send(:"#{model.__title_sane_prop}=", (self.send(model.__title_base_prop) || '').sanitize)
          end

          true
        end
      end

    end
  end

  Model.append_extensions(Is::Titlable)
end