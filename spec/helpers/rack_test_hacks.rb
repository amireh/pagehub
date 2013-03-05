module Rack::Test
  class Session
    alias_method :_post, :post
    def post(uri, params = {}, env = {}, &block)
      _post(uri,params.to_json,env,&block)
    end

    alias_method :_put, :put
    def put(uri, params = {}, env = {}, &block)
      _put(uri,params.to_json,env,&block)
    end

  end
end