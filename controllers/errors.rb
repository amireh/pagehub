def on_api_error(msg = response.body)
  status response.status

  errmap = {}

  msg = case
  when msg.is_a?(String)
    [ msg ]
  when msg.is_a?(Array)
    msg
  when msg.is_a?(Hash)
    errmap = msg
    msg.collect { |k,v| v }
  when msg.is_a?(DataMapper::Validations::ValidationErrors)
    errmap = msg.to_hash
    msg.to_hash.collect { |k,v| v }.flatten
  else
    [ "unexpected response: #{msg}" ]
  end

  {
    :status        => 'error',
    :messages      => msg,
    :field_errors  => errmap
  }
end

error Sinatra::NotFound do
  return if @internal_error_handled
  @internal_error_handled = true


  if api_call?
    content_type :json
    if settings.test?
      on_api_error("No such resource. URI: #{request.path}, Params: #{params.inspect}").to_json
    else
      on_api_error("No such resource.").to_json
    end
  else
    erb :"404", :layout => :"layouts/guest"
  end
end

error 400, :provides => [ :json, :html ] do
  return if @internal_error_handled
  @internal_error_handled = true

  respond_to do |f|
    f.html {
      session["flash"]["error"] = response.body
      return redirect back
    }
    f.json { on_api_error.to_json }
  end
end

[ 401, 403, 404 ].each do |http_rc|
  error http_rc, :provides => [ :json, :html ] do
    return if @internal_error_handled
    @internal_error_handled = true

    respond_to do |f|
      f.html { erb :"#{http_rc}", :layout => :"layouts/guest" }
      f.json { on_api_error.to_json }
    end
  end
end

error 500 do
  return if @internal_error_handled
  @internal_error_handled = true

  if !settings.intercept_internal_errors
    raise request.env['sinatra.error']
  end

  begin
    courier.report_error(request.env['sinatra.error'])
  rescue Exception => e
    # raise e
  end

  respond_to do |f|
    f.html { erb :"500", :layout => :"layouts/guest" }
    f.json { on_api_error("Internal error").to_json }
  end
end