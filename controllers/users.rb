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

def demo_password
  "funkydemo123"
end

get '/demo', auth: :guest, provides: [ :html ] do
  @user = User.create({
    nickname: "demo-#{tiny_salt}".sanitize,
    name:     "PageHub Demo",
    provider: "pagehub",
    email:    "demo@pagehub.org",
    password: demo_password,
    password_confirmation: demo_password
  })

  unless @user
    flash[:error] = "We're sorry, we could not launch a demo for you at this moment. Please try again later."
    return redirect '/'
  end

  authorize(@user)

  redirect '/'
end

post '/users',
  auth: :guest,
  provides: [ :html ] do

  api_required!({
    nickname: nil,
    email:    nil,
    password: nil,
    password_confirmation: nil
  })

  api_optional!({
    name: nil
  })

  # Create the user with a UUID
  u = User.new(api_params({
    provider: "pagehub"
  }))

  u.name ||= u.nickname

  unless u.save
    flash[:error] = u.all_errors
    return redirect back
  end

  flash[:notice] = "Welcome to PageHub! Your new personal account has been created."
  authorize(u)

  redirect u.dashboard_url
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

  if params[:no_object]
    halt 200, {}.to_json
  end

  respond_to do |f|
    f.json { rabl :"users/show", object: @user }
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