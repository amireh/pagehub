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
          default: '',
          messages: {
            presence: 'A title must be provided.',
            length:   'Title must be at least 3 characters long.'
          }
        }.deep_merge(options)
        
        base_prop = options[:property].to_sym
        sane_prop = "pretty_#{base_prop}".to_sym
        
        property base_prop, DataMapper::Property::String, length: 120, default: options[:default]
        property sane_prop, DataMapper::Property::String, length: 120
        
        validates_presence_of base_prop, message: options[:messages][:presence]
        validates_length_of   base_prop, within: 3..120, message: options[:messages][:length]
        
        @title_base_prop = base_prop
        @title_sane_prop = sane_prop
        
        before :valid?, :validate_title
      end

      module ClassMethods
        attr_reader :title_base_prop, :title_sane_prop
      end
      
      module InstanceMethods
        def validate_title(*ctx)
          if attribute_dirty?(model.title_base_prop)
            self.send(:"#{model.title_sane_prop}=", (self.send(model.title_base_prop) || '').sanitize)
          end
          
          true
        end
      end
      
    end
  end

  Model.append_extensions(Is::Titlable)
end