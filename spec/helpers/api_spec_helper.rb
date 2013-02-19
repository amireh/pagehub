module RSpec
  module APIResponseMatchers
    class Fail
      def initialize(http_rc = 400, *keywords)
        @http_rc  = http_rc
        @keywords = (keywords || []).flatten
        @raw_keywords = @keywords.dup
      end

      def matches?(api_rc)
        if api_rc.is_a?(Proc)
          api_rc = api_rc.yield
        end
        
        @api_rc = api_rc

        return false if api_rc.http_rc != @http_rc
        return false if api_rc.status  != :error

        if @keywords.empty?
          return true if api_rc.messages.empty?
          return false
        end
        
        if @keywords.size == 1
          @keywords = @keywords.first.split(/\s/)
        end

        @keywords = Regexp.new(@keywords.join('.*'))

        matched = false
        api_rc.messages.each { |m|
          if m.match(@keywords)
            matched = true
            break
          end
        }
        
        matched
      end # Fail#matches

      def failure_message
        m = "Expected: \n"
        
        if @api_rc.status != :error
          m << "* The API response status to be :error, but got #{@api_rc.status}\n"
        end
        
        if @api_rc.http_rc != @http_rc
          m << "* The HTTP RC to be #{@http_rc}, but got #{@api_rc.http_rc}\n"
        end
                
        formatted_keywords = @raw_keywords.join(' ')
        
        if @raw_keywords.any? && @api_rc.messages.any?
          m << "* One of the following API response messages: \n"
          m << @api_rc.messages.collect.with_index { |m, i| "\t#{i+1}. #{m}" }.join("\n")
          m << "\n  to be matched by the keywords: #{formatted_keywords}\n"
          
        elsif @raw_keywords.any? && @api_rc.messages.empty?
          m << "* The API response to contain some messages (got 0) and for at least\n" <<
               "  one of them to match the keywords #{formatted_keywords}\n"
               
        elsif @raw_keywords.empty? && @api_rc.messages.any?
          m << "* The API response to contain no messages, but got: \n"
          m << @api_rc.messages.collect.with_index { |m, i| "\t#{i+1}. #{m}" }.join("\n")
          m << "\n"
        end
        
        m
      end
      
      # def negative_failure_message
      #   "expected API response [status:#{@api_rc.status}] not to be :error, " <<
      #   "and API response [messages: #{@api_rc.messages}] not to match '#{@keywords}'"
      # end
    end # Fail
    
    class Success
      def initialize(http_rc = 200)
        @http_rc = http_rc
      end
      
      def matches?(api_rc)
        if api_rc.is_a?(Proc)
          api_rc = api_rc.yield
        end
        
        @api_rc = api_rc
        
        return false if api_rc.http_rc != @http_rc
        return false if api_rc.status  != :success
        
        true
      end
      
      def failure_message
        m = "Expected:\n"
        
        if @api_rc.status != :success
          m << "* The API response status to be :success, but got #{@api_rc.status}\n"
        end
        
        if @api_rc.http_rc != @http_rc
          m << "* The HTTP RC to be #{@http_rc}, but got #{@api_rc.http_rc}\n"
        end
        
        if @api_rc.messages.any?
          m << "* The API response messages to be empty, but got: \n"
          m << @api_rc.messages.collect.with_index { |m, i| "\t#{i+1}. #{m}" }.join("\n")
          m << "\n"
        end
        
        m
      end
      
      # def negative_failure_message
      #   m = "expected API response [status:#{@api_rc.status}] not to be :success"
      #   if @api_rc.messages.any?
      #     m << ", and no messages, but got: #{@api_rc.messages}"
      #   end
      #   m
      # end      
    end

    def fail(http_rc = 400, *keywords)
      Fail.new(http_rc, keywords)
    end
    
    def succeed(http_rc = 200)
      Success.new(http_rc)
    end
  end
end

module Rack
  module Test
    class APIResponse
      attr_reader :rr, :body, :status, :messages, :http_rc

      def initialize(rack_response)
        @rr       = rack_response
        @http_rc  = @rr.status
        begin;
          @body     = JSON.parse(@rr.body.empty? ? '{}' : @rr.body)
        rescue JSON::ParserError => e
          raise "Invalid API response;" <<
          "body could not be parsed as JSON:\n#{@rr.body}\nException: #{e.message}"
        end
        
        @status   = :success
        @messages = []
        
        unless blank?
          if @body.is_a?(Hash)
            @status   = @body["status"].to_sym  if @body.has_key?("status")
            @messages = @body["messages"]       if @body.has_key?("messages")
          elsif @body.is_a?(Array)
            @messages = @body
          else
            @messages = @body
          end
        end
      end
      
      def blank?
        @body.empty?
      end
      
      def succeeded?
        !blank? && @status == :success
      end
      
      def failed?
        !blank? && @status == :error
      end      
    end # APIResponse
  end # Test
end # Rack

# Converts a Rack::Test HTTP mock response into an API one.
#
# @see Rack::Test::APIResponse
#
# @example usage
#   rc = api_call get '/api/endpoint'
#   rc.should fail(400, 'some error explanation')
#   rc.should succeed(201)
#   rc.messages.empty?.should be_true
#   rc.status.should == :error
#
# @example using expect {}
#   expect { api_call get '/foobar' }.to succeed(200)
def api_call(rack_response)
  Rack::Test::APIResponse.new(rack_response)
end

# Does the same thing as #api_call but wraps it into a block.
#
# @example usage
#   api { get '/api/endpoint' }.should fail(403, 'not authorized')
#
# @see #api_call
def api(&block)
  api_call(block.yield)
end

module Router
  class << self
    def puts(*args)
      super(*args) if $VERBOSE
    end
    
    # Locates routes defined for any verb containing the provided token.
    #
    # @param [String] token the token the route should contain
    # @return [Array<Hash, Fixnum>] a map of all the verb routes, and the count of located routes
    def routes_for(token)
      all_routes = {}
      count  = 0
      Sinatra::Application.routes.each do |verb_routes|
        verb, routes = verb_routes[0], verb_routes[1]
        all_routes[verb] ||= []
        routes.each_with_index do |route, i|
          route_regex = route.first.source
          if route_regex.to_s.include?(token)
            all_routes[verb] << route
            count += 1
            
            puts "Route located: #{verb} -> #{route_regex.to_s}"
          end
        end
        all_routes[verb].uniq!
      end
      [ all_routes, count ]
    end
    
    def purge(token)
      routes, nr_routes = *routes_for(token)
      
      # puts "cleaning up #{nr_routes} routes"
      
      routes.each_pair do |verb, vroutes|
        vroutes.each do |r| delete_route(verb, r) end
      end
      
      yield(nr_routes) if block_given?
      
      nr_routes
    end
    
    protected
    
    def delete_route(verb, r)
      verb_routes = Sinatra::Application.routes.select { |v| v == verb }.first
      
      unless verb_routes
        raise "Couldn't find routes for verb #{verb}, that's impossible"
      end
      
      unless verb_routes[1].delete(r)
        raise "Route '#{r}' not found for verb #{verb}"
      end
    end
    
  end
end

# Will remove any /spec* Sinatra route defined manually
# by a spec using app.[verb] '/spec/*' {}
def cleanup_routes(token = 'spec')
  Router.purge('spec') do |_|
    Router.routes_for(token).last.should == 0
  end
end

RSpec.configure do |config|
  config.include RSpec::APIResponseMatchers
end
