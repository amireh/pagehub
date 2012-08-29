module DataMapper
  module Resource
    def collect_errors
      out = []; errors.each { |e| out << e }; out.join("\n")
    end
  end
end