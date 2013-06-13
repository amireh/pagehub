configure do
  allowed_origin = settings.cors['allowed_origin'] || ''
  allowed_origin = :any if allowed_origin.empty?

  # CORS
  set :protection, :except => [ :http_origin ]
  set :allow_methods, [ :get, :options ]
  set :allow_origin, allowed_origin
  set :allow_headers, ["*", "Content-Type", "Accept", "Cache-Control", 'X-Requested-With']
  set :allow_credentials, false
  set :max_age, "1728000"
  set :expose_headers, ['Content-Type']
end