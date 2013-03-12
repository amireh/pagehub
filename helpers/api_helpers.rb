module Sinatra

  # TODO: accept nested parameters
  module API
    module Helpers
      def api_call?
        (request.accept || '').to_s.include?('json')
      end

      # Define the required API arguments map. Any item defined
      # not found in the supplied parameters of the API call will
      # result in a 400 RC with a proper message marking the missing
      # field.
      #
      # The map is a Hash of parameter keys and optional validator blocks.
      #
      # @example A map of required API call arguments
      #   api_required!({ title: nil, user_id: nil })
      #
      # Each entry can be optionally mapped to a validation proc that will
      # be invoked *if* the field was supplied. The proc will be passed
      # the value of the field.
      #
      # If the value is invalid and you need to suspend the request, you
      # must return a String object with an appropriate error message.
      #
      # @example Rejecting a title if it's rude
      #   api_required!({
      #     :title => lambda { |t| return "Don't be rude" if t && t =~ /rude/ }
      #   })
      #
      # @note
      #   The supplied value passed to validation blocks is not pre-processed,
      #   so you must make sure that you check for nils or bad values in validator blocks!
      def api_required!(args, h = params)
        args.each_pair { |name, cnd|
          if cnd.is_a?(Hash)
            api_required!(cnd, h[name])
            next
          end

          parse_api_argument(h, name, cnd, :required)
        }
      end

      # Same as #api_required! except that fields defined in this map
      # are optional and will be used only if they're supplied.
      #
      # @see #api_required!
      def api_optional!(args, h = params)
        args.each_pair { |name, cnd|
          if cnd.is_a?(Hash)
            api_optional!(cnd, h[name])
            next
          end

          parse_api_argument(h, name, cnd, :optional)
        }
      end

      # Consumes supplied parameters with the given keys from the API
      # parameter map, and yields the consumed values for processing by
      # the supplied block (if any).
      #
      # This is useful if:
      #  1. a certain parameter does not correspond to a model attribute
      #     and needs to be renamed, or is used in a validation context
      #  2. the data needs special treatment
      #  3. the data needs to be (re)formatted
      #
      def api_consume!(keys)
        keys = [ keys ] unless keys.is_a?(Array)
        keys.each do |k|
          if val = @api[:required].delete(k.to_sym)
            yield(val) if block_given?
          end

          if val = @api[:optional].delete(k.to_sym)
            yield(val) if block_given?
          end
        end
      end

      def api_has_param?(key)
        @api[:optional].has_key?(key)
      end

      def api_param(key)
        @api[:optional][key.to_sym] || @api[:required][key.to_sym]
      end

      # Returns a Hash of the *supplied* request parameters. Rejects
      # any parameter that was not defined in the REQUIRED or OPTIONAL
      # maps (or was consumed).
      #
      # @param Hash q A Hash of attributes to merge with the parameters,
      #               useful for defining defaults
      def api_params(q = {})
        @api[:optional].deep_merge(@api[:required]).deep_merge(q)
      end

      # Attempt to locate a resource based on an ID supplied in a request parameter.
      #
      # If the param map contains a resource id (ie, :folder_id),
      # we attempt to locate and expose it to the route.
      #
      # A 404 is raised if:
      #   1. the scope is missing (@space for folder, @space or @folder for page)
      #   2. the resource couldn't be identified in its scope (@space or @folder)
      #
      # If the resources were located, they're accessible using @folder or @page.
      #
      # The route can be halted using the :requires => [] condition when it expects
      # a resource.
      #
      # @example using :requires to reject a request with an invalid @page
      #   get '/folders/:folder_id/pages/:page_id', :requires => [ :page ] do
      #     @page.show    # page is good
      #     @folder.show  # so is its folder
      #   end
      #
      def __api_locate_resource(r, container = nil)

        resource_id = params[r + '_id'].to_i
        rklass      = r.capitalize

        collection = case
        when container.nil?;  eval "#{rklass}"
        else;                 container.send("#{r.to_plural}")
        end

        # puts "locating resource #{r} with id #{resource_id} from #{collection} [#{container}]"

        resource = collection.get(resource_id)

        if !resource
          m = "No such resource: #{rklass}##{resource_id}"
          if container
            m << " in #{container.class.name.to_s}##{container.id}"
          end
          halt 404, m
        end

        instance_variable_set('@'+r, resource)

        resource
      end

      private

      def parse_api_argument(params, name, cnd, type)
        cnd ||= lambda { |*_| true }
        name = name.to_s

        unless [:required, :optional].include?(type)
          raise ArgumentError, 'API Argument type must be either :required or :optional'
        end

        if !params.has_key?(name)
          if type == :required
            halt 400, "Missing required parameter :#{name}"
          end
        else
          if cnd.respond_to?(:call)
            errmsg = cnd.call(params[name])
            halt 400, { :"#{name}" => errmsg } if errmsg && errmsg.is_a?(String)
          end

          @api[type][name.to_sym] = params[name]
        end
      end
    end

    def self.registered(app)
      app.helpers Helpers
      app.before do
        @api = { required: {}, optional: {} }
        @parent_resource = nil

        if api_call?
          # puts "its an api call"
          # puts request.content_type
          request.body.rewind
          body = request.body.read.to_s || ''
          unless body.empty?
            begin;
              params.merge!(::JSON.parse(body))
              # puts params.inspect
              # puts request.path
            rescue ::JSON::ParserError => e
              puts e.message
              puts e.backtrace
            end
          end
        end
      end

      app.set(:requires) do |*resources|
        condition do
          @required = resources.collect { |r| r.to_s }
          @required.each { |r| @parent_resource = __api_locate_resource(r, @parent_resource) }
        end
      end

    end
  end

  register API
end