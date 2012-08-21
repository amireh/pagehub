Warden::Strategies.add(:pagehub) do
  def valid?
    [ "email", "password" ].each { |field|
      if !params.has_key?(field) || params[field].empty? then
        return false
      end
    }
    params.length == 2
  end

  def authenticate!
    puts "Authenticating with the PageHub strategy"

    u = User.authenticate(params["email"], params["password"])
    u.nil? ? fail!("Login failed. Please verify your credentials and try again.") : success!(u)
  end
end