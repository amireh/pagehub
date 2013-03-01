def sign_out
  authorize '', ''
end

def sign_in(u = @u)
  raise 'Must create a mockup user before signing in' unless u

  authorize u.email, Fixtures::UserFixture.password
end