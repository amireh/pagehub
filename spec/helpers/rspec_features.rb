module RSpec
  module Core
    module DSL
      alias_method :feature, :describe
    end
    class ExampleGroup
      class << self
        alias_method :scenario, :it
      end
    end
  end
end