helpers do

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
  end

  def p(*args)
    scope = @space || @user || current_user

    if scope && scope.respond_to?(:p)
      scope.p(*args)
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


  def is_on?(*args)
    scope = @space || @user || current_user

    if scope && scope.respond_to?(:is_on?)
      scope.is_on?(*args)
    end
  end

  def is_on(*setting)
    value = p(*setting)

    case nil
    when block_given?; yield(value)
    else;              is_on?(*setting)
    end
  end

  def checkify(setting, &condition)
    is_on(setting, &condition) ? 'checked="checked"' : ''
  end

  def selectify(setting, &condition)
    is_on(setting, &condition) ? 'selected="selected"' : ''
  end

  def disabilify(setting, &condition)
    is_on(setting, &condition) ? 'disabled="disabled"' : ''
  end
end