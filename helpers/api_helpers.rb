module Sinatra
  module API
    module Helpers
      def api_call?
        (request.accept || '').to_s.include?('json')
      end
      
      def api_required!(args)
        args.each_pair { |name, cnd|
          if cnd.is_a?(Hash)
            api_required!(cnd)
            next
          end
          
          parse_api_argument(name, cnd, :required)
        }        
      end
      
      def api_optional!(args)
        args.each_pair { |name, cnd|
          if cnd.is_a?(Hash)
            api_optional!(cnd)
            next
          end
          
          parse_api_argument(name, cnd, :optional)
        }
      end
      
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

      def api_params(q = {})
        @api[:optional].merge(@api[:required]).merge(q)
      end
      
      # def api_resources(params)
      #   params.each_pair do |k,v|
      #     puts "checking if #{k} is a resource indicator"
      #     if k.to_s =~ /.*_id/
      #       @parent_resource = locate_resource(k.gsub('_id', ''), @parent_resource)
      #     end
      #   end
      # end
      
      def api_locate_resource(r, container = nil)
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

        # @folder = locate_folder if required?(:folder)
        # @page   = locate_page   if required?(:page)
        # resource = send("locate_#{r}")
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
      
      def parse_api_argument(name, cnd, type)
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
            halt 400, errmsg if errmsg && errmsg.is_a?(String)
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
      end
      
      app.set(:requires) do |*resources|
        condition do
          @required = resources.collect { |r| r.to_s }
          @required.each { |r| @parent_resource = api_locate_resource(r, @parent_resource) }
        end
      end
      
    end
  end
  
  register API
end