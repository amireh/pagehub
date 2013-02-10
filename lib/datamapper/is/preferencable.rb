require 'dm-core'
require 'dm-types'

module DataMapper
  module Is
    module Preferencable

      def is_preferencable(options = {}, defaults = {})
        extend DataMapper::Is::Preferencable::ClassMethods
        include DataMapper::Is::Preferencable::InstanceMethods

        options = {
          :on => :settings
        }.merge(options)
        
        property options[:on].to_sym, DataMapper::Property::Text, default: '{}'
        
        @@default_preferences = defaults
      end

      module ClassMethods
        def set_default_preferences(p)
          @@default_preferences = p
        end
      end
      
      module InstanceMethods
        
        def preferences(*scope)
          if scope.length == 1 && scope.first.is_a?(String)
            scope = scope.first.split('.')
          end
          
          @preferences ||= @@default_preferences.deep_merge(JSON.parse(self.settings))
          scoped_preferences = @preferences
          scope.each { |s| scoped_preferences = scoped_preferences[s.to_s] || {} }
          scoped_preferences
        end
        
        alias_method :p, :preferences
      end
      
    end
  end

  Model.append_extensions(Is::Preferencable)
end