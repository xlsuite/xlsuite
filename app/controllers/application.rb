#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ApplicationController < ActionController::Base
  include XlSuite::AuthenticatedSystem
  layout :choose_layout

  helper_method :current_domain, :current_domain?, :current_account, :current_account?, :current_superuser?
  helper_method :current_settings
  helper_method :current_user_member_of?
  helper_method :last_incoming_request
  helper_method :current_user_is_master_account_owner?
  helper_method :current_user_is_account_owner?

  # Filter out sensitive parameters from the log and exception emails
  filter_parameter_logging :password, :credit_card
  
  # We must ensure this filter runs before authenticating through a cookie
  prepend_before_filter :load_current_domain

  prepend_before_filter :log_incoming_requests
  prepend_before_filter :set_default_title
  
  before_filter :get_absolute_current_page_url
  before_filter :get_current_page_uri

  before_filter :check_account_expiration
  before_filter :massage_dates_and_times

  before_filter :remove_values_as_labels, :only => %w(create update)
  
  before_filter :block_until_paid_in_full
  before_filter :set_affiliate_account_ids_session

  prepend_after_filter :set_content_type

  # turn off sessions if this is a request from a robot
  session :off, :if => proc { |request| Utility.robot?(request.user_agent) }
  
  filter_parameter_logging :credit_card

  include SslRequirement

  class Utility
    def self.robot?(user_agent)
      user_agent =~ /\b(Baidu|Gigabot|Google|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
    end
  end

  protected
  def set_affiliate_account_ids_session
    # immediately return if no affiliate ids parameter supplied
    return true if params[AFFILIATE_IDS_PARAM_KEY].blank?
    # set affiliate ids session based on affiliate ids parameter
    # overwrite value of affiliate ids session if affiliate ids session is blank
    # otherwise only replace the last session id in the affiliate ids session with the first affiliate id provided in param
    if session[AFFILIATE_IDS_SESSION_KEY].blank?
      param_affiliate_ids = params[AFFILIATE_IDS_PARAM_KEY].split(",").map(&:strip).reject(&:blank?).uniq
      return true if param_affiliate_ids.empty?
      @_affiliate_account_ids = AffiliateAccount.find(:all, :select => "username", :conditions => {:username => param_affiliate_ids}).map(&:username)
      session[AFFILIATE_IDS_SESSION_KEY] = @_affiliate_account_ids.join(",")
    else
      session_ids = session[AFFILIATE_IDS_SESSION_KEY].split(",").map(&:strip).reject(&:blank?)
      param_affiliate_ids = params[AFFILIATE_IDS_PARAM_KEY].split(",").map(&:strip).reject(&:blank?).uniq
      @_affiliate_account_ids = AffiliateAccount.find(:all, :select => "username", :conditions => {:username => param_affiliate_ids}).map(&:username)
      session_ids += @_affiliate_account_ids
      session_ids.uniq!
      session[AFFILIATE_IDS_SESSION_KEY] = session_ids.join(",")
    end
    return true
  end
  
  def ssl_required? 
    # Default behavior of ssl_required?
    ssl_required = (self.class.read_inheritable_attribute(:ssl_required_actions) || []).include?(action_name.to_sym)
    
    # Enable ssl only when in production mode
    ssl_required && ENV["RAILS_ENV"] == "production" 
  end
  
  def load_current_domain
    if request.host =~ /^w+\./
      @www_domain = Domain.find_by_name(request.host)
      
      # if the www domain is not found, redirect to non-www version immediately
      unless @www_domain
        headers["Status"] = "301 Moved Permanently"
        redirect_to("http://"+(request.host.gsub(/^w+\./,'') + request.env["REQUEST_URI"])) and return false
      end
      
      @current_domain = Domain.find_by_name_and_account_id(request.host.gsub(/^w+\./,''), @www_domain.account_id)
      if @current_domain
        headers["Status"] = "301 Moved Permanently"
        redirect_to("http://"+(@current_domain.name + request.env["REQUEST_URI"])) and return false
      end
    end
    
    @current_domain = Domain.find_by_name(request.host, :include => :account, :conditions => "accounts.confirmation_token IS NOT NULL")
    
    if @current_domain && params[:action] =~ /confirm|activate/i && params[:controller] == "accounts" && !params[:code].blank?
      return true
    end
    return true if @current_domain && params[:controller] == "public/account_templates"
    
    @current_domain = Domain.find_by_name(request.host, :include => :account, :conditions => "accounts.confirmation_token IS NULL AND domains.activated_at IS NOT NULL")
    @current_domain = Domain.new(:name => request.host) unless @current_domain
    logger.info {"**> Domain: #{current_domain.name.inspect}, request.host: #{request.host.inspect}, new_record? #{current_domain.new_record?.inspect}"}
    if Object.const_defined?(:NewRelic) && !@current_domain.new_record? then
      NewRelic::Agent.add_request_parameters(:account_id => @current_domain.account.id, :domain_id => @current_domain.id, :domain_name => @current_domain.name)
    end
    return true unless @current_domain.new_record?

    # Domain does not exist, and we're probably trying to buy it now, go on
    logger.debug {"self.controller_name = #{self.controller_name.inspect}, self.controller_path = #{self.controller_path.inspect}, self.action_name = #{self.action_name.inspect}, self.request.method = #{self.request.method.inspect}"}
    return true if self.controller_path == "accounts" && 
      ((self.action_name == "new" && request.get?) || (self.action_name == "create" && request.post?))

    # Domain does not exist, we offer the choice of buying it now
    @domain = @current_domain
    @acct = @domain.build_account
    @owner = @acct.build_owner
    @address = @owner.main_address
    @email = @owner.main_email
    @phone = @owner.main_phone
    @title = "#{@domain.name} | New Account Registration"
    @_parent_domain = self.get_request_parent_domain
    render :template => "accounts/new.html.erb", :status => "404 Not Found", :content_type => "text/html; charset=UTF-8", :layout => "plain-html"
    return false
  end

  def current_domain?
    !current_domain.nil?
  end

  def current_domain
    @current_domain
  end

  def current_account?
    current_domain? && !current_account.nil?
  end

  def current_account
    current_domain.account
  end

  def check_account_expiration
    return unless current_user?
    if current_account.expired? && current_user == current_account.owner
      redirect_to(payment_account_path(current_account))
      return false
    end

    case
    when current_account.nearly_expired?
      flash_warning :now, "This account is nearly expired."
    when current_account.expired?
      flash_warning :now, "This account has expired.  Access denied."
      render :template => "shared/account_expired", :status => "503 Account Expired"
      return false
    end
  end
  
  def block_until_paid_in_full
    return unless current_account.order
    if current_account.order.balance.zero?
      current_account.order = nil
      current_account.save!
      return
    end
    render :template => "accounts/not_paid_in_full", :layout => "no-column"
    #redirect_to not_paid_in_full_account_path(current_account)
  end

  def log_incoming_requests
    session[:incoming_requests] ||= Array.new
    unless request.xhr?
      session[:incoming_requests].unshift(request.env['REQUEST_URI'])
      session[:incoming_requests].pop if session[:incoming_requests].length > 20
    end
  end

  def rescue_action_with_logging(exception)
    logger.warn { "==> #{exception.class.name}: #{exception.message}"}
    case exception
    when  ActiveRecord::RecordNotFound, ::ActionController::RoutingError,
      ::ActionController::UnknownAction, ::ActionController::UnknownController
      # NOP, don't notify of 404s
    else
      logger.error exception
      logger.error exception.backtrace.join("\n")
      ExceptionNotifier.deliver_exception_caught(exception, self, 
         :request => request,
         :response => performed? ? response : nil,
         :session => session,
         :current_user => current_user? ? current_user : nil,
         :domain => current_domain,
         :account => current_account,
         :incoming_requests => session[:incoming_requests])
    end
    rescue_action_without_logging(exception)
  end

  alias_method_chain :rescue_action, :logging if RAILS_ENV == 'production'

  def rescue_action_in_public(exception)
    case exception
    when  ActiveRecord::RecordNotFound, ::ActionController::RoutingError,
          ::ActionController::UnknownAction, ::ActionController::UnknownController
      render(:missing)
    else
      render(:error)
    end
  end

  def template_path_for_name(template_name)
    "shared/rescues/public/#{template_name}.rhtml"
  end

  def master_account
    @master_account ||= Account.find_by_master(true)
  end

  def set_content_type
    response.headers['Content-Type'] = 'text/html; charset=UTF-8' \
        if response.headers['Content-Type'].blank?
  end

  def self.in_place_edit_for(object, attribute, options={})
    define_method("set_#{object}_#{attribute}") do
      @item = object.to_s.camelize.constantize.find(params[:id])
      @item.update_attribute(attribute, params[:value])
      @value = @item.send(attribute)
      @extras = params[:extra_updates] ? params[:extra_updates].split(' ') : []
      render :template => 'shared/in_place_editor_result', :layout => false
    end
  end

  def massage_dates_and_times(root=params)
    root.each_pair do |k, v|
      next massage_dates_and_times(v) if v.kind_of?(Hash)
      next if v.blank?
      key = k.to_s
      next unless key =~ /(?:date|_(at|on))$/
      begin
        dt = Chronic.parse(v.gsub(/[^\s\w:\/]/, ' '))
        next unless dt
        root[k] = key[/on$/] || key[/date/i] ? dt.to_date : dt
      rescue
        logger.debug {"Error parsing #{k}:#{v.inspect} using Chronic\n#{$!}\n#{$!.backtrace.join("\n")}"}
        next
      end
    end

    true
  end

  def current_superuser?
    current_user? && current_user.superuser?
  end

  def render_with_selector(*args, &block)
    args.flatten!
    case args.first.to_s
    when "redirect"
      response.headers["Status"] = args.last.kind_of?(Hash) ? args.last[:status] : nil
      redirect_to args[1]
    when "missing"
      render_using_public_layout(:template => "shared/rescues/missing", :status => "404 Not Found")
    when "error"
      render_using_public_layout(:template => "shared/rescues/error", :status => "500 Internal Server Error")
    when "unauthorized"
      render_using_public_layout(:template => "shared/rescues/unauthorized", :status => "401 Unauthorized")
    else
      render_without_selector(*args, &block)
    end
  end

  alias_method_chain :render, :selector

  # This filter removes attributes which have been left to their default values.
  # For example, a PhoneContactRoute could come in as:
  #  {"name" => "Name", "number" => "111-222-3333", "extension" => "Extension"}
  #
  # After passing through this filter, the Hash will be modified to this:
  #  {"number" => "111-222-3333"}
  def remove_values_as_labels(root=params)
    root.each_pair do |key, value|
      remove_values_as_labels(value) if value.kind_of?(Hash)
      root.delete(key) if key.to_s.humanize.titleize == value
    end
  end

  # Renders the action's body within a Layout named "Public"
  def render_within_public_layout(options={})
    render_using_public_layout(options)
  end
  
  # Renders the action's body within a Layout named "Public", unless
  def render_using_public_layout(options={})
    @_frontend = true
    content_for_layout = render(options.merge(:layout => false))
    status = options[:status] || "200 OK"
    erase_render_results

    # We build ourselves a temporary page which we'll render in the next step.
    # Note the :layout reference.
    @page = Page.new(:account => current_account, :behavior => "plain_text",
        :body => content_for_layout, :layout => "Public",
        :title => @title)

    request_params = params.clone
    request_params.delete("controller")
    request_params.delete("action")
    request_params.delete("path")

    p_options = {:current_account => current_account,
      :current_domain => current_domain, :current_page_url => get_absolute_current_page_url,
      :params => request_params, :logged_in => current_user?}
    p_options.merge!(:current_user => current_user) if self.current_user?

    render_options = @page.render_on_domain(current_domain, p_options)

    render(render_options.reverse_merge(:layout => false, :status => status))
  end
    
  def redirect_to_specified_or_default(default_url)
    return redirect_to(params[:return_to]) unless params[:return_to].blank? 
    redirect_to default_url
  end

  def render_auto_complete(collection)
    @objects = collection
    @q = params[:q]
    render(:template => "tags/auto_complete", :layout => false)
  end

  def current_user_member_of?(group_name)
    current_user? && current_user.member_of?(group_name)
  end
  
  def absolute_url(path)
    return path if path =~ %r{^(?:https?)://}
    request.host_with_port + "/#{path}".gsub(Regexp.new("/{2,}"),"/")
  end
  
  def get_absolute_current_page_url
    @_current_page_url ||= request.protocol + request.host_with_port + request.request_uri
  end
  
  def get_current_page_uri
    @_current_page_uri ||= request.request_uri
  end
  
  def absolute_current_domain_url
    request.protocol + request.host_with_port
  end
  
  def choose_layout
    "two-columns"
  end
  
  def last_incoming_request
    incoming_requests = session[:incoming_requests].reject {|e| e =~ REJECTED_RETURN_TO_PATH}
    last_incoming_request = incoming_requests.first
    return nil if last_incoming_request.blank? || !current_user?
    last_incoming_request
  end
  
  def set_default_title
    params_clone = params.clone
    @title = params_clone.delete(:controller).humanize + " | " + params_clone.delete(:action).humanize
  end
  
  def convert_to_auto_complete_json(array)
    json_collection = []
    array.each do |item|
      if item.size > 2
        json_collection << "{'display':#{item.first.to_json}, 'value':#{item[1].to_json}, 'id':#{item.last.to_json}}"
      else
        json_collection << "{'display':#{item.first.to_json}, 'value':#{item.first.to_json}, 'id':#{item.last.to_json}}"
      end
    end
    json_collection = json_collection.join(",")
    %Q!{'total':#{array.size}, 'collection':[#{json_collection}]}!
  end
  
  def redirect_to_return_to_or_back
    if params[:return_to]
      redirect_to params[:return_to]
      return
    end
    redirect_to :back 
  end
  
  def redirect_to_return_to_or_back_or_home
    params_return_to = nil
    if params[:return_to]
      params_return_to = params[:return_to].dup
      params_return_to.gsub!(/_+id_+/i, @_target_id.to_s) if @_target_id
      params_return_to.gsub!(/_+uuid_+/i, @_target_uuid.to_s) if @_target_uuid
    end
    redirect_to params_return_to || request.env["HTTP_REFERER"] || "/"
  end
  
  def redirect_to_next_or_back_or_home
    params_next = nil
    if params[:next]
      params_next = params[:next].dup
      params_next.gsub!(/_+id_+/i, @_target_id.to_s) if @_target_id
      params_next.gsub!(/_+uuid_+/i, @_target_uuid.to_s) if @_target_uuid
    end
    redirect_to params_next || request.env["HTTP_REFERER"] || "/"
  end

  def load_cart
    load_user_latest_cart
    return if @cart
    @cart = current_account.carts.find(session[:cart_id]) if session[:cart_id]
    return if @cart
    initialize_cart
    rescue ActiveRecord::RecordNotFound
      initialize_cart
  end
  
  def load_user_latest_cart
    return unless current_user?
    @cart = current_user.cart
    session[:cart_id] = @cart.id if @cart
  end
    
  def initialize_cart
    @cart = current_account.carts.build
    @cart.domain = self.current_domain
    @cart.invoice_to = current_user if current_user?
  end
  
  def create_cart
    return unless @cart.new_record?
    @cart.save! 
    session[:cart_id] = @cart.id
  end
  
  def assemble_images_to_json(raw_records, options={})
    options.delete_if {|key, value| value.blank?}
    records = []
    raw_records.each do |raw_record|
      records << {
        :id => raw_record.id,
        :filename => raw_record.filename,
        :url => download_asset_path(options.merge(:id => raw_record.id))
      }
    end
    {:collection => records}.to_json
  end
  
  def get_request_parent_domain
    parts = request.host.split(".")
    parts.shift
    (0..parts.size).to_a.map {|index| parts[index..-1]}.reject(&:blank?).each do |domain_parts|
      candidate_name = domain_parts.join(".")
      domain = Domain.find_by_name(candidate_name)
      return domain if domain
    end
    Domain.find_by_name("xlsuite.com")      
  end
  
  def flash_messages_to_s
    flashes = []
    flashes << flash[:notice]
    flashes << flash[:message]
    flashes << flash[:warning]
    flashes.flatten.compact.map(&:strip).join(", ")
  end
  
  def render_messages_as_ul(messages, options={})
    options.reverse_merge!(:class => "response-messages-list")
    raise SyntaxError, "Input need to be of Array type" unless messages.kind_of?(Array)
    out = ["<ul class='#{options[:class]}'>"]
    messages.each do |message|
      out << "<li>#{message}</li>"
    end
    out  << "</ul>"
    out.to_s
  end
  
  def render_error_messages_for(symbol)
    render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => symbol.to_sym})
  end
  
  def master_account_owner
    Account.find_by_master(true).owner
  end
  
  def current_user_is_master_account_owner?
    return false unless self.current_user?
    self.current_user.id == self.master_account_owner.id
  end
  
  def current_user_is_account_owner?
    return false unless self.current_user?
    self.current_user.id == self.current_account.owner.id
  end
  
  private
  def ensure_proper_protocol
    return true
  end
end
