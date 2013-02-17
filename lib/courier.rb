class Courier
  attr_accessor :options
  attr_reader   :configured
  
  def initialize(o)
    self.options = {
      enabled:  true,
      test:     false,
      host:     'localhost',
      app_name: 'Courier',
      from:     'noreply@localhost',
      admin:    'admin@localhost'
    }.merge(o)
    
    @configured = false
  end
  
  def configure(credentials)
    Pony.options = {
      :via => :smtp,
      :via_options => {
        :address    => credentials['address'],
        :port       => credentials['port'],
        :user_name  => credentials['key'],
        :password   => credentials['secret'],
        :enable_starttls_auto => true,
        :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
        :domain => "HELO", # don't know exactly what should be here
      }
    }
    
    @configured = true
  end
  
  def dispatch_email_verification(u, &cb)
    dispatch_email(u.email,
      "emails/verification",
      "Please verify your email '#{u.email}'") do |success, msg|
      
      if success
        u.pending_notices({ type: 'email' })
        @n.update({ dispatched: true })
      end

      cb.call(success, msg) if block_given?
    end
  end

  def dispatch_temp_password(u, &cb)
    dispatch_email(u.email, "emails/temp_password", "Temporary account password") do |success, msg|
      
      if success
        u.pending_notices({ type: 'password' })
        @n.update({ dispatched: true })
      end

      cb.call(success, msg) if block_given?
    end
  end
  
  def report_error(error)
    @error = error
    dispatch_email(options['admin'], 'emails/error_report', "Error report #{Time.now.strftime("%D")}")
  end
  
  # TODO: background this
  def dispatch_email(addr, tmpl, title, &cb)
    unless options['enabled']
      # puts ">> Courier service disabled << [testing? #{options['test']}]"
      if options['test'] == true
        cb.call(true, 'Courier service is currently turned off.') if block_given?
      else
        cb.call(false, 'Courier service is currently turned off.') if block_given?
      end
      
      return
    end

    # puts ">> Courier service engaged. Delivering to #{addr}: #{title}"

    sent = true
    error_msg = 'Mail could not be delivered, please try again later.'
    
    begin
      Pony.mail :to => addr,
                :from =>    options['from'],
                :subject => "[#{options['app_name']}] #{title}",
                :html_body => erb(tmpl.to_sym, layout: :"layouts/mail")
    rescue Exception => e
      error_msg = "Mail could not be delivered: #{e.message}"
      sent = false
    end

    cb.call(sent, error_msg) if block_given?
  end
end

module Sinatra
  module Courier
    def self.registered(app)
      app.set :courier, ::Courier.new(app.settings.courier)
      app.helpers do
        def courier
          settings.courier
        end
      end
    end
  end
  
  register Courier
end
