module Sinatra  
  module Authenticator
    module Helpers
      Messages = {
        lacks_privilege: "You lack privilege to visit this section.",
        unauthorized:    "You must sign in first"
      }
      
      def logged_in?
        # support HTTP basic auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        if @auth.provided? && @auth.basic? && @auth.credentials
          if u = authenticate(@auth.credentials.first, @auth.credentials.last, true)
            authorize(u)
          end
        end

        !current_user.nil?
      end

      def current_user
        return @user if @user

        return nil unless session[:id]
        @user = User.get(session[:id])
      end

      def authenticate(email, pw, encrypt = true)
        User.first({
          provider: 'pagehub',
          email:    email,
          password: encrypt ? User.encrypt(pw) : pw
        })
      end
      
      def restricted!
        halt 401, Messages[:unauthorized] unless logged_in?
      end

      def restrict_to(roles, options = {})
        roles = [ roles ] if roles.is_a? Symbol

        if roles.include?(:guest)
          if logged_in?
            halt 403, "You're already logged in."
          end

          return true
        end

        restricted!
        @user = current_user

        if options[:with].is_a?(Hash)
          options[:with].each_pair { |k, v|
            unless @user[k] == v
              halt 403, Messages[:lacks_privilege]
            end
          }
        elsif options[:with].is_a?(Proc)
          unless options[:with].call(@user)
            halt 403, Messages[:lacks_privilege]
          end
        end
         
        # @access_roles = roles - [:user] # used by locate_space
      end

      private
      
      def required?(r)
        (@required || []).include?(r.to_s)
      end
      
      # def locate_folder
      #   if !@space
      #     halt 404, "No space was specified."
      #   end
        
      #   @space.folders.get(params[:folder_id].to_i)
      # end
      
      # def locate_page
      #   if !@space
      #     halt 404, "No space was specified."
      #   end
        
      #   @space.pages.get(params[:page_id].to_i)
      # end      

      # def locate_space
      #   s = case
      #   when params[:space_id]
      #     @user.spaces.get(params[:space_id].to_i)
      #   when params[:space]
      #     @user.spaces.first({ pretty_title: params[:space].to_s })
      #   else
      #     nil
      #   end
        
      #   if s
      #     # Verify the role of the user in this space, if any specified
      #     (@access_roles || []).each do |role|
      #       unless s.send("#{role}?", current_user)
      #         halt 403, "You must be #{role.to_s.vowelize} in this space."
      #       end
      #     end
      #   end
        
      #   s
      # end

      def authorize(user)
        # if user.link
        #   # reset the state vars
        #   @user = nil
        #   @account = nil

        #   # mark the master account as the current user
        #   session[:id] = user.link.id

        #   # refresh the state vars
        #   @user     = current_user
        #   @account  = current_account
        # else
          session[:id] = user.id
        # end
      end
      
      
    end
    
    def self.registered(app)
      app.set(:auth) do |*roles| condition do restrict_to(roles) end end
      app.helpers Helpers
    end
  end
  
  register Authenticator
end
