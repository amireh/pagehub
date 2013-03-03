# before do
#   if logged_in? && current_user.auto_nickname && flash.empty?
#     flash[:notice] = "You have an auto-generated nickname, please go to your profile page and update it."
#   end
# end

get '/signup', auth: :guest do
  erb :"/users/new"
end

get '/users/lookup/by_nickname',
  auth: [ :admin ],
  provides: [ :json ] do

  nn = params[:nickname]

  halt 200, [].to_json if nn.empty?

  respond_with User.all(:nickname.like => "#{nn}%", limit: 10).collect { |u|
    out = { id: u.id, nickname: u.nickname }
    if respond_to?(:gravatar_url)
      out[:gravatar] = gravatar_url(u.gravatar_email, :size => 24)
    end
    out
  }
end

post '/users/name', :auth => :user, provides: [ :json ] do
  respond_to do |f|
    f.json { { available: nickname_available?(params[:name]) }.to_json }
  end
end

get '/users/:user_id',
  auth: [ :user ],
  provides: [ :json ],
  requires: [ :user ],
  exclusive: true do

  @user = current_user

  respond_with @user do |f|
    # f.html { erb :"users/dashboard" }
    f.json { rabl :"users/show"     }
  end
end

get '/demo', auth: :guest, provides: [ :html ] do
  @user = User.create({
    nickname: "demo-#{salt}".sanitize,
    name:     "PageHub Demo",
    provider: "pagehub",
    email:    "demo@pagehub.org",
    password: "funkydemo123",
    password_confirmation: "funkydemo123"
  })

  unless @user
    flash[:error] = "We're sorry, we could not launch a demo for you at this moment. Please try again later."
    return redirect '/'
  end

  authorize(@user)

  redirect '/'
end

post '/users', auth: :guest, provides: [ :html ] do
  p = params

  # Validate input
  {
    "Your email can not be empty" => !p[:email] || p[:email].to_s.empty?,
    "That email is already registered" => User.first(email: p[:email]),
    "You must fill in your name" => !p[:name] || p[:name].to_s.empty?,
    "You must type the same password twice" => p[:password].empty? || p[:password_confirmation].empty?,
    "The passwords you entered do not match" => p[:password] != p[:password_confirmation],
    "Passwords must be at least 5 characters long." => p[:password].length <= 4
  }.each_pair { |msg, cnd|
    if cnd then
      flash[:error] = msg
      return redirect back
    end
  }

  # Encrypt the password
  params[:password] = Digest::SHA1.hexdigest(params[:password])

  nickname = params[:name].to_s.sanitize
  auto_nn = false
  if u = User.first({ nickname: nickname }) then
    nickname = "#{nickname}_#{tiny_salt}"
    auto_nn = true
  end

  params.delete("password_confirmation")

  # Create the user with a UUID
  u = User.create(params.merge({ uid: UUID.generate, nickname: nickname, auto_nickname: auto_nn, provider: "pagehub" }))

  unless u.saved?
    flash[:error] = u.collect_errors
    return redirect back
  end

  flash[:notice] = "Welcome to PageHub! Your new personal account has been registered."
  session[:id] = u.id

  redirect '/'
end

put '/users/:user_id',
  auth: [ :user ],
  provides: [ :json ],
  requires: [ :user ],
  exclusive: true do

  authorize! :manage, @user, message: "You can not do that."

  api_optional!({
    name: nil,
    nickname: nil,
    gravatar_email: nil,
    email: nil,
    preferences: nil,

    current_password: lambda { |pw|
      pw ||= ''

      if !pw.empty? && User.encrypt(pw) != current_user.password
        return "The current password you entered is wrong."
      end

      true
    },

    password: nil,
    password_confirmation: nil
  })

  api_consume! :preferences do |prefs|
    @user.save_preferences(@user.preferences.deep_merge(prefs))
  end

  api_consume! :current_password

  unless @user.update(api_params)
    halt 400, @user.errors
  end

  respond_to do |f|
    f.json {
      rabl :"users/show", object: @user
    }
  end
end

get "/settings",
  auth: [ :user ],
  provides: [ :html  ] do

  @user = current_user

  respond_with @space do |f|
    f.html { erb :"/users/settings/index" }
  end
end

# get '/settings/verify/:type', auth: :user do |type|
#   dispatch = lambda { |addr, tmpl|
#     Pony.mail :to => addr,
#               :from => "noreply@pagehub.org",
#               :subject => "[PageHub] Please verify your email '#{addr}'",
#               :html_body => erb(tmpl.to_sym, layout: "layouts/mail".to_sym)
#   }

#   redispatch = params[:redispatch]

#   @type = type.to_sym

#   case type
#   when "primary"
#     @address = current_user.email
#     if !redispatch && current_user.verified?(@address)
#       return erb :"/emails/already_verified"
#     elsif !redispatch && current_user.awaiting_verification?(@address)
#       return erb :"/emails/already_dispatched"
#     else
#       if redispatch
#         current_user.email_verifications.first({ address: @address }).destroy
#       end

#       unless @ev = current_user.verify_address(@address)
#         halt 500, "Unable to generate a verification link: #{current_user.collect_errors}"
#       end

#       dispatch.call(current_user.email, "emails/verification")
#     end
#   end

#   erb :"/emails/dispatched"
# end

# get '/users/:user_id/verify/:token', auth: :user, requires: [ :user ], exclusive: true do |uid, token|
#   unless @ev = @scope.email_verifications.first({ salt: token })
#     halt 400, "No such verification link."
#   end

#   if @ev.expired?
#     return erb :"emails/expired"
#   elsif @ev.verified?
#     flash[:error] = "Your email address '#{@ev.address}' is already verified."
#     return redirect "/settings/profile"
#   else
#     @ev.verify!
#     flash[:notice] = "Your email address '#{@ev.address}' has been verified."
#     return redirect "/settings/profile"
#   end
# end