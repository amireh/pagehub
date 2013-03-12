module Helpers
  module Preferences
    # mapping of displayable font names to actual CSS font-family names
    FontMap = {
      "Proxima Nova" => "ProximaNova-Light",
      "Ubuntu" => "UbuntuRegular",
      "Ubuntu Mono" => "UbuntuMonoRegular",
      "Monospace" => "monospace, Courier New, courier, Mono",
      "Arial" => "Arial",
      "Verdana" => "Verdana",
      "Helvetica Neue" => "Helvetica Neue"
    }

    def p(key, scope = nil)
      scope ||= @space || @user || current_user || DefaultPreferences

      if scope && scope.respond_to?(:p)
        scope.p(key)
      end
    end

    # Loads the user's preferences merging them with the defaults
    # for any that were not overridden.
    #
    # Side-effects:
    # => @preferences will be overridden with the current user's settings
    # @deprecated
    #
    # def preferences(scope = current_user)
    #
    #   if !scope
    #     return settings.default_preferences
    #   elsif @preferences && @preferences[scope.to_s]
    #     return @preferences[scope.to_s]
    #   end
    #
    #   @preferences ||= {}
    #   prefs = scope.settings
    #   if prefs && !prefs.empty?
    #     begin; @preferences[scope.to_s] = JSON.parse(prefs); rescue; end
    #   end
    #
    #   defaults = settings.default_preferences.dup
    #   @preferences[scope.to_s] = defaults.deep_merge(@preferences[scope.to_s])
    #   @preferences[scope.to_s]
    # end

    # alias_method :preferences, :p


    def is_on?(key, scope = nil)
      scope ||= @space || @user || current_user

      if scope && scope.respond_to?(:is_on?)
        scope.is_on?(key)
      end
    end

    def is_on(key, scope = nil)
      value = p(key, scope)

      case
      when block_given?; yield(value)
      else;              is_on?(key)
      end
    end

    def checkify(setting = nil, scope = nil, &condition)
      checked = setting ? is_on(setting, scope, &condition) : condition.call
      checked ? 'checked="checked"' : ''
    end

    def selectify(setting = nil, scope = nil, &condition)
      selected = setting ? is_on(setting, scope, &condition) : condition.call
      selected ? 'selected="selected"' : ''
    end

    def disabilify(setting = nil, scope = nil, &condition)
      disabled = setting ? is_on(setting, scope, &condition) : condition.call
      disabled ? 'disabled="disabled"' : ''
    end
  end # Preferences
end # Helpers

helpers do
  include Helpers::Preferences
end