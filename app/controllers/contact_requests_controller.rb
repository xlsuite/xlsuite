#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ContactRequestsController < ApplicationController
  required_permissions %w(new create bugs bug_buster) => true,
      %w(index show destroy complete update destroy_collection tagged_collection mark_as_ham mark_as_spam) => :edit_contact_requests
  before_filter :load_contact_request, :only => %w(show destroy complete update)

  def index    
    respond_to do |format|
      format.html
      format.js 
      format.json do
        case params[:status]
        when /^completed$/i
          conditions = {:conditions => ["completed_at < ?", Time.now]}
        when /^incomplete$/i
          conditions = {:conditions => ["completed_at IS NULL"]}
        when /^spam$/i
          conditions = {:conditions => ["approved_at IS NULL"]}
        else
          conditions = {:conditions => ["approved_at IS NOT NULL"]}
        end
        
        params[:start] = 0 unless params[:start]
        params[:limit] = 50 unless params[:limit]
        
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "created_at DESC" : "#{params[:sort]} #{params[:dir]}") 
    
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        
        @contact_requests = current_account.contact_requests.search(query_params, search_options.merge(conditions))
        @contact_requests_count = current_account.contact_requests.count_results(query_params, conditions)
        
        render :json => {:collection => self.assemble_records(@contact_requests), :total => @contact_requests_count}.to_json
      end
    end
  end

  def show
    @title = "#{@contact_request.name}'s Contact Request"
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @title = "Submit a Contact Request"
    @contact_request = current_account.contact_requests.build
  end

  def create
    # party is set to current user if the request of create contact request is made while a user is logged in
    # otherwise, finds party based on email address provided if there is any
    # if party is still not find, instantiate a new party object after defensio determines it's not spam
    @error_messages = []
    
    params[:party] ||= {}
    if params[:party][:group_labels]
      params[:party][:group_labels] = params[:party][:group_labels].split(",") if params[:party][:group_labels].is_a?(String)

      groups = current_account.groups.find(:all, :select => "groups.id", :conditions => {:label => params[:party].delete(:group_labels).map(&:strip).reject(&:blank?)})
      params[:party][:group_ids] = groups.map(&:id).join(",") unless groups.empty?
    end
    
    ContactRequest.transaction do
      if params.has_key?(:email_address) then
        params[:email_address].each do |name, attrs|
          route = current_account.email_contact_routes.find_by_address_and_routable_type(attrs[:email_address], "Party")
          next unless route
          next unless route.routable_type =~ /party/i
          @party = route.routable
          break
        end
      end
      
      contact_request_params = params[:contact_request].blank? ? {} : Marshal::load(Marshal.dump(params[:contact_request]))
      if params[:party]
        name = params[:party][:full_name].blank? ? "#{params[:party][:first_name]} #{params[:party][:middle_name]} #{params[:party][:last_name]}" : 
                                params[:party][:full_name]
        name = name.gsub(/\s+/, " ").strip
        contact_request_params = contact_request_params.reverse_merge({:name => name}) unless name.blank?
      end
      
      @contact_request = @party ? @party.contact_requests.build(contact_request_params.merge({:request_ip => request.remote_ip, :referrer_url => request.referer})) : 
                                  current_account.contact_requests.build(contact_request_params.merge({:request_ip => request.remote_ip, :referrer_url => request.referer})) 
      @contact_request.account = current_account
      @contact_request.domain = current_domain
      
      if params[:party][:group_ids]
        params[:party][:group_ids] = params[:party][:group_ids].split(",") if params[:party][:group_ids].is_a?(String)
        params[:party][:group_ids] = params[:party][:group_ids].map(&:strip).reject(&:blank?)
      end
      
      if @party 
        # update blank attributes of parties if party params is specified
        if params[:party]
          if params[:party][:tag_list]
            @party.tag_list = @party.tag_list << ", #{params[:party].delete(:tag_list)}"
          end
          if params[:party][:group_ids]            
            current_account.groups.find(params[:party][:group_ids]).to_a.each do |g|
              @party.groups << g unless @party.groups.include?(g)
            end
            @party.update_effective_permissions = true
            params[:party].delete(:group_ids)
          end
          params[:party].each do |key, value|
            @party.send("#{key}=".to_sym, value) if @party.send(key.to_sym).blank? rescue next 
          end
        end
        @party.save!
        # checks for valid contact routes: contact routes that has main identifier filled in
        @error_messages = @contact_request.save_contact_routes_to_party(@party, params)
      else
        @contact_request.params = params
      end
      
      @content = params[:contact_request].blank? ? "" : (params[:contact_request][:body] || "")
      unless params[:extra].blank?
        extra = ""
        
        params[:extra].each_pair do |k, v|
          if v.respond_to?(:read) then
            #it's an asset
            asset = current_account.assets.build(:uploaded_data => v)
            asset.owner = @party if @party
            asset.save!
            extra << "#{k.to_s.humanize}: #{download_asset_url(:id => asset.reload.id, :host => current_domain.name)}<br />"
            params[:extra].delete(k)
          else
            extra << "#{k.to_s.humanize}: #{v.to_s}<br />"
          end
        end
        @content << "<br />Additional Parameters:<br />" + extra
      end
      
      @contact_request.email = params[:email_address].values.map{|a| a[:email_address]}.join(", ") rescue nil
      if @contact_request.email.blank? && current_user?
        @contact_request.email = current_user.main_email.email_address rescue nil
      end
      @contact_request.email = nil if @contact_request.email.blank?
      @contact_request.build_body(params, @content)
      
      unless params[:profile_ids].blank?
        @contact_request.recipients = current_account.parties.find(:all, :conditions => ["profile_id IN (?)", params[:profile_ids].split(",")])
        @contact_request.tag_list = @contact_request.tag_list + ", third_party"
      end
      
      if @contact_request.save
        ContactRequestCheckerFuture.create!(:args => {:id => @contact_request.id, :domain_id => current_domain.id}, 
                                            :account => @contact_request.account, :owner => @contact_request.party || current_account.owner)
        #contact request is successfully saved, clear error messages
        @error_messages.clear
      else
        @error_messages << @contact_request.errors.full_messages
      end
    end
    
    flash[:liquid] ||= {}
    flash[:liquid][:params] = params
    
    if !@error_messages.blank?
      @error_messages = @error_messages.flatten
      flash_failure @error_messages
    end
    return render(:action => "new") if params[:contact_request].blank?
    if @error_messages.blank?
      flash_success params[:success_message] || "Contact request submitted"
      return redirect_to(params[:return_to]) unless params[:return_to].blank?
      return render(:text => "<html><head><title></title></head><body><h1>Thanks</h1><p>Thank you for your submission</p></body></html>")
    end
    
    return redirect_to(:back) if request.env["HTTP_REFERER"]
    render(:missing)
  end
  
  def update
    case params[:contact_request][:completed]
    when /^true$/i  
      @contact_request.completed_at = Time.now()
    when /^false$/i
      @contact_request.completed_at = nil
    end
    @contact_request.tag_list = params[:contact_request][:tag_list] if params[:contact_request][:tag_list]
    if @contact_request.save
      flash_success "Contact request sucessfully updated"
    end
    respond_to do |format|
      format.html
      format.js { render(:json => truncate_record(@contact_request.reload).to_json)}
    end
  end
  
  def destroy
    @contact_request.destroy
    flash_success "Contact request destroyed"
    redirect_to contact_requests_path
  end

  def destroy_collection
    @destroyed_items_id = []
    @undestroyed_items_size = 0
    @destroyed_parties_id = []
    ContactRequest.transaction do
      current_account.contact_requests.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |contact_request|
        id = contact_request.id
        party = contact_request.party
        if contact_request.destroy
          @destroyed_items_id << id
          party_id = party.id
          if params[:destroy_party] && party && (party.id != current_user.id) && party.destroy 
            @destroyed_parties_id << party_id
          end
        else
          @undestroyed_items_size += 1
        end
      end
    end
    
    error_message = []
    error_message << "#{@destroyed_items_id.size} contact request(s) successfully deleted" if @destroyed_items_id.size > 0
    error_message << "#{@destroyed_parties_id.size} parties(s) successfully deleted" if @destroyed_parties_id.size > 0
    error_message << "#{@undestroyed_items_size} contact request(s) failed to be destroyed" if @undestroyed_items_size > 0
    
    flash_success :now, error_message.join(", ") 
    respond_to do |format|
      format.js
    end
  end
  
  def tagged_collection
    count = 0
    current_account.contact_requests.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |contact_request|
      contact_request.tag_list = contact_request.tag_list + " #{params[:tag_list]}"
      contact_request.save
      count += 1
    end
    flash_success :now, "#{count} contact_request(s) successfully tagged"
    render :update do |page|
      page << update_notices_using_ajax_response(:onroot => "parent")
    end
  end
  
  def mark_as_spam
    count = 0
    current_account.contact_requests.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |contact_request|
      contact_request.confirm_as_spam!
      count += 1
    end
    flash_success :now, "#{count} contact_request(s) successfully marked as spam"
    render :update do |page|
      page << refresh_grid_datastore_of("contact_requests")
      page << update_notices_using_ajax_response
    end
  end
  
  def mark_as_ham
    count = 0
    current_account.contact_requests.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |contact_request|
      contact_request.confirm_as_ham!
      count += 1
    end
    flash_success :now, "#{count} contact_request(s) successfully marked as ham"
    render :update do |page|
      page << refresh_grid_datastore_of("contact_requests")
      page << update_notices_using_ajax_response
    end
  end

  def complete
    @contact_request.complete!
    flash_success "Contact request completed"
    respond_to do |format|
      format.html { redirect_to contact_request_path(@contact_request) }
      format.js
    end
  end
  
  def bugs
    recipient_email_address = current_domain.get_config(:bug_report_recipients) 
    recipient_email_address = current_account.owner.main_email.email_address if recipient_email_address.blank?
  
    options = params[:bug].merge(:account_id => current_account.id, :tos => recipient_email_address, :scheduled_at => Time.now(),
                :sender => {:address => current_user? ? current_user.main_email.email_address : "unknown" }, :inline_attachments => true, :mass_mail => false)

    options[:subject] = "Bug report: #{options[:subject].inspect}"
    default_body_top = "<p>Sent from domain: #{current_domain.name}" 
    default_body_top << "</p><p>URL: #{params[:page_url]}</p><p>" unless params[:page_url].blank?
    default_body_top << "</p><p>Logged in: #{params[:logged_in]}</p><p>" unless params[:logged_in].blank?
    default_body_top << "</p><p>-----------------</p><p>"
    
    options[:body] = default_body_top << options[:body].gsub("\r\n", "</p><p>")
    
    unless params[:extra].blank?
      extra = ""
      
      params[:extra].each_pair do |k, v|
        extra << "#{k.to_s.humanize}: #{v.to_s}<br />"
      end
      options[:body] << "<br />" + extra
    end
    
    begin
      @email = Email.create!(options)
      @email.tag_list = 'sent, bug'
      unless (params[:attachment] && params[:attachment][:uploaded_data].blank?)
        asset = current_account.assets.create!(params[:attachment].merge(:owner => current_user)) 
        @email.assets << asset
      end
      @email.release!
    rescue
      # We ignore any cascaded failures.
      # This is to prevent the user from having to fill out a bug report about a failed bug report
      logger.error "Could not deliver bug report: #{$!}"
      logger.error $!.backtrace.join("\n")
      raise unless RAILS_ENV == "production"
    end

    redirect_url = params[:next].blank? ? current_domain.get_config(:bug_thank_you_page) : params[:next]
    if redirect_url.blank?
      render :template => "shared/bug_thank_you"
    else
      redirect_to redirect_url
    end
  end
  
  def bug_buster
    @title = "Bug Buster"
  end

  protected
  def load_contact_request
    @contact_request = current_account.contact_requests.find(params[:id])
  end
  
  def extra_params_is_blank?
    return true if params[:extra].blank?
    blank = true
    params[:extra].each do |key, value|
      blank = false if !(value.to_s).blank?
    end
    return blank
  end
  
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end
  
  def truncate_record(record)
    timestamp_format = "%d/%m/%Y"
    {
      :id => record.id,
      :name => record.name,
      :created_at => record.created_at.strftime(timestamp_format),
      :updated_at => record.updated_at.strftime(timestamp_format),
      :completed_at => record.completed_at ? record.completed_at.strftime(timestamp_format) : "",
      :completed => record.completed_at ? true : false,
      :subject => record.subject,
      :domain_id => record.domain_id,
      :domain_name => record.domain ? record.domain.name : "Unknown",
      :party_id => record.party_id,
      :party_email => (record.party && record.party.main_email) ? record.party.main_email.email_address : record.email,
      :flash => flash[:notice].to_s
    }
  end
end
