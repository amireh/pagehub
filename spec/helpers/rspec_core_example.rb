class RSpec::Core::Example
  def passed?
    @exception.nil?
  end
  
  def failed?
    !passed?
  end
end