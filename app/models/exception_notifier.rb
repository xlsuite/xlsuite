#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

require "singleton"
require "net/http"
require "net/https"
require "uri"

class ExceptionNotifier
  PARAM_FILTER_REPLACEMENT = "[FILTERED]"
  FOGBUGZ_URL = URI.parse("https://teksol.fogbugz.com/ScoutSubmit.asp")

  class Nameless
    include Singleton

    def name
      "Nameless"
    end
  end

  def self.deliver_exception_caught(exception, controller, options={})
    name          = exception.class.name
    message       = exception.message
    backtrace     = exception.clean_backtrace
    app_backtrace = exception.application_backtrace
    
    request = options.delete(:request)
    if request
      # Filter environment variables
      filtered_env_request = request.env.inject({}) do |hash, (k, v)|
        if (k =~ /RAW_POST_DATA/i)
          hash[k] = PARAM_FILTER_REPLACEMENT
        else
          hash[k] = self.filter_parameters(controller, {
            k=> v
          }).values[0]
        end
        hash
      end if request.env
      # Filter request parameters
      filtered_params_request = filter_parameters(controller, request.parameters) if request.parameters
    end
    
    # Normalize the message to prevent duplicates from popping up
    message.gsub!(/0x[0-9A-F]{8,}/i, "0x00000000")
    if message["Mysql::Error"] then
      first = message[/^.+:\s/]
      if first then
        rest = message.sub(first, "")
        rest.gsub!("''", "?")
        rest.gsub!(/'[^']*'/, "?")
        rest.gsub!(/\d+/, "?")
        original_message = message
        message = first + rest
      end
    end
    
    notify_bugscout!(
      :name                  => name,
      :message               => message,
      :original_message      => original_message,
      :full_backtrace        => backtrace,
      :application_backtrace => app_backtrace,
      :request_parameters    => filtered_params_request,
      :environment           => filtered_env_request,
      :session               => options[:session],
      :current_account       => options[:current_account] || options[:account],
      :current_domain        => options[:current_domain] || options[:domain],
      :current_user          => options[:current_user] || Nameless.instance,
      :version               => XlSuite.version
    )
  end
  
  def self.notify_bugscout!(params)
    first_line = params[:application_backtrace].first
    match = first_line.match(/(\w+)[.]\w+:(\d+):in `([^']+)'$/)
    subject = "%s on %s %s\#%s:%s (%s) v:#{params[:version]}" % [params[:message].inspect, params[:current_domain] || params[:current_account].respond_to?(:domain_name) ? params[:current_account].domain_name : "xlsuite.com", match[1].classify, match[3], match[2], params[:name]]

    extra = Hash.new
    extra["Account"]              = params[:current_account].domain_name if params[:current_account] && params[:current_account].respond_to?(:domain_name)
    extra["Account"]            ||= "xlsuite.com (inferred)"
    extra["Domain"]               = params[:current_domain].name if params[:current_domain]
    extra["User"]                 = params[:current_user].name.to_s if params[:current_user]
    extra["Message"]              = params[:original_message] if params[:original_message]
    extra["Request Parameters"]   = params[:request_parameters]
    extra["Request Environment"]  = params[:environment]
    extra["Complete Backtrace"]   = params[:full_backtrace]
    extra["Appliation Backtrace"] = params[:app_backtrace]
    extra["Session"]              = {"ID" => params[:session].session_id, "Data" => params[:session].data} unless params[:session].blank?

    req = Net::HTTP::Post.new(FOGBUGZ_URL.path, "Accept" => "application/xml")
    form_data = {
      "ScoutUserName"    => "Unassigned",
      "ScoutProject"     => "XLsuite.com",
      "ScoutArea"        => "Backend",
      "Description"      => subject,
      "Extra"            => extra.to_yaml,
      "Email"            => (params[:current_user].respond_to?(:main_email) ? params[:current_user].main_email.address : "coder@xlsuite.com").to_s,
      "FriendlyResponse" => "0"
    }

    logger.debug {"POSTing data to FogBugz BugScout:\n#{form_data.to_yaml}"}
    req.set_form_data(form_data)

    res = nil
    power = Net::HTTP.new(FOGBUGZ_URL.host, FOGBUGZ_URL.port)
    power.use_ssl = (FOGBUGZ_URL.scheme == "https")
    res = power.start do |http|
      http.read_timeout = 5 # seconds
      http.open_timeout = 2 # seconds
      begin
        http.request(req)
      rescue TimeoutError
        nil
      end
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      logger.warn {"Successfully reported exception to FogBugz BugScout"}
    else
      logger.warn {"Failed to report exception to FogBugz BugScout"}
    end
    logger.warn { res.body }
  end
  
  # Filter parameters based on filter_parameter_logging in the controller
  def self.filter_parameters(controller, params)
    if controller.respond_to?(:filter_parameters)
      controller.send(:filter_parameters, params)
    elsif controller.nil?
      params
    else
      controller.params
    end
  end

  def self.logger
    RAILS_DEFAULT_LOGGER
  end
end
