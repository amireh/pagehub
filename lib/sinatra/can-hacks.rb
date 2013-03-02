require 'sinatra/can'

module Sinatra
  module Can
    module Helpers
      # alias_method :cancan_current_user, :current_user

      # def current_ability
      #   @current_ability = settings.local_ability.new(cancan_current_user, cancan_current_space) if settings.local_ability.include?(CanCan::Ability)
      #   @current_ability ||= ::Ability.new(cancan_current_user, cancan_current_space)
      # end

      def authorize!(action, subject, options = {})
        if current_ability.cannot?(action, subject, options)
          halt 403, options[:message] || settings.messages[:forbidden]
        end
      end

      protected

      # def cancan_current_space
      #   @cancan_current_space ||= instance_eval(&self.class.current_space_block) if self.class.current_space_block
      # end

    end


    module Hacks
      # def cancan_space(&block)
      #   @current_space_block = block
      # end

      # def current_space_block
      #   @current_space_block
      # end

      def self.registered(app)
        app.set(:can) { |action, *a|
          subject, options = *a
          condition { authorize!(action, subject, options) }
        }
      end
    end

  end
  register Can::Hacks
end