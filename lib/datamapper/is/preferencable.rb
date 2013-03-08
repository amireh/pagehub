require 'dm-core'
require 'dm-types'

module DataMapper
  module Is
    module Preferencable

      def is_preferencable(options = {}, defaults = {})
        extend  ClassMethods
        include InstanceMethods

        options = {
          :on => :settings
        }.merge(options)

        property options[:on].to_sym, DataMapper::Property::Text, default: '{}'

        @preferencable_options  = options
        @default_preferences    = defaults
      end

      module ClassMethods
        attr_accessor :default_preferences, :preferencable_options
      end

      module InstanceMethods

        def get_preference(k = nil)
          # if k.is_a?(String)
          #   k = k.split('.')
          # else
          #   unless k.is_a?(Array)
          #     raise RuntimeError,
          #       'preference key must be either a String or an Array of strings' <<
          #       " got #{k.class} => #{k.inspect}"
          #   end
          # end

          prefs = preferences

          if k && k.is_a?(String)
            k.split('.').each { |key|
              prefs = prefs[key]
            }
          end

          prefs
        end

        def preferences
          unless @preferences
            model_prefs = attribute_get(model.preferencable_options[:on] || {}).to_s
            model_prefs = '{}' if model_prefs.empty?

            @preferences = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
            @preferences.merge! model.
              default_preferences.
                deep_merge JSON.parse model_prefs
          end
          @preferences
        end

        def save_preferences(prefs = @preferences)
          self.update!({
            :"#{model.preferencable_options[:on]}" => prefs.to_json.to_s
          })
        end

        alias_method :p, :get_preference

        def is_on?(*setting)
          value = get_preference(*setting)

          if block_given?
            return yield(value)
          end

          case value
          when String
            !value.empty? && !%w(off false).include?(value)
          when Hash
            !value.empty?
          when TrueClass
            true
          when FalseClass
            false
          when NilClass
            false
          else
            !value.nil?
          end
        end
      end

    end
  end

  Model.append_extensions(Is::Preferencable)
end