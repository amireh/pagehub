module PageHub
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
    end


    def self.password_salt()
      rand(36**16).to_s(32)[0..6]
    end

    def self.tiny_salt(r = 3)
      Base64.urlsafe_encode64 Random.rand(1234 * (10**r)).to_s(8)
    end

    def self.sane_salt(pepper)
      Base64.urlsafe_encode64( pepper + Time.now.to_s)
    end

    def self.salt(pepper = "")
      pepper = Random.rand(12345 * 1000).to_s if pepper.empty?
      pepper = pepper + Random.rand(1234).to_s
      sane_salt(pepper)
    end
  
    def p(*args)
      scope = @group || @user || current_user
      if scope && scope.respond_to?(:preferences)
        scope.preferences(*args)
      end
    end
    
    def is_on(*setting)
      value = p(*setting)
      
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
      end
    end
    def checkify(setting, &condition)
      is_on(setting, &condition) ? 'checked="checked"' : ''
    end
    
    def selectify(setting, &condition)
      is_on(setting, &condition) ? 'selected="selected"' : ''
    end
    
    def disabilify(setting)
      is_on(setting, &condition) ? 'disabled="disabled"' : ''
    end
    
    def md(content)
      content.to_s.to_markdown
    end

    def __host
      request.referer.scan(/http:\/\/[^\/]*\//).first[0..-2]
    end

    # Loads the user's preferences merging them with the defaults
    # for any that were not overridden.
    #
    # Side-effects:
    # => @preferences will be overridden with the current user's settings
    def preferences(scope = current_user)

      if !scope
        return settings.default_preferences
      elsif @preferences && @preferences[scope.to_s]
        return @preferences[scope.to_s]
      end

      @preferences ||= {}
      prefs = scope.settings
      if prefs && !prefs.empty?
        begin; @preferences[scope.to_s] = JSON.parse(prefs); rescue; end
      end

      defaults = settings.default_preferences.dup
      @preferences[scope.to_s] = defaults.deep_merge(@preferences[scope.to_s])
      @preferences[scope.to_s]
    end

    def pretty_time(datetime)
      datetime.strftime("%D")
    end

    def pluralize(number, word)
      number == 1 ? "#{number} #{word}" : "#{number} #{word}s"
    end
    
    def vowelize(word)
      word.to_s.vowelize
    end
  end
end

class String
  Vowels = ['a','o','u','i','e']
  def vowelize
    Vowels.include?(self[0]) ? "an #{self}" : "a #{self}"
  end
end

helpers do
  include PageHub::Helpers

  def name_available?(name)
    nn = name.to_s.sanitize
    !reserved?(nn) && !nn.empty? && User.first(nickname: nn).nil? && Group.first(name: nn).nil?
  end

  ReservedNames = [ 'name', 'pages', 'groups' ]
  def reserved?(name)
    ReservedNames.include?(name)
  end
end