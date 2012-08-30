module DataMapper
  module Resource

    def collect_errors
      out = []; errors.each { |e| out << e }; out.join("\n")
    end

    # For some reason, resource.valid? keeps returning true
    # even if the validations failed, so we use a custom persisted?
    # method to validate the model's id which will be set only if
    # the object persisted.
    def persisted?
      !self.id.nil?
    end
  end
end