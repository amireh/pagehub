helpers do
  def logged_in?
    session[:authorized]
  end

  def current_user
    if !logged_in? then
      return nil
    end

    if @user then
      return @user
    end

    @user = User.first(email: session[:email])
    @user
  end

  def restricted!
    halt 401 unless logged_in?
  end

end

get '/signup' do
  erb :"/users/new"
end

post '/signup' do
  if User.first(email: params[:email]) then
    flash[:error] = "That email is already registered!"
    return redirect "/signup"
  end

  params[:password] = Digest::SHA1.hexdigest(params[:password])

  u = User.create(params)
  if u then
    flash[:notice] = "Congratulations! Your new personal account has been registered."
  else
    flash[:error] = "Oops! We're sorry but something bad happened while creating your \
    new account, please try again."
    return redirect "/signup"
  end

  session[:authorized] = true
  session[:email] = u.email

  redirect '/'
end

get '/login' do
  erb :"/login"
end

post '/login' do
  pw = Digest::SHA1.hexdigest(params[:password])
  u = User.first({ password: pw, email: params[:email] })
  if u then
    session[:authorized] = true
    session[:email] = u.email
  else
    flash[:error] = "Incorrect email or password, please try again."
    return redirect "/login"
  end

  # flash[:notice] = "Welcome #{u.name.split.first}! You're now logged in."
  redirect '/'
end


get '/logout' do
  session[:authorized] = false
  session[:email] = nil

  flash[:notice] = "Bye!"
  redirect back
end