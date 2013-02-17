module PageHub
  module Config
    class << self
      def init(file = 'config/preferences.json')
        @@defaults ||= load(file)
      end
      
      def load(file)
        JSON.parse(File.read(File.join($ROOT, file)))
      end
      
      def defaults
        @@defaults
      end
      
      def get(*key)
      end
    end
  end
end