#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProfileRequestsController < ApplicationController
  required_permissions %w(index new create_add create_claim) => true,
      %w(approve_collection edit destroy_collection) => :edit_profiles
  
  def index    
    respond_to do |format|
      format.html
      format.js 
      format.json do
        
        params[:start] = 0 unless params[:start]
        params[:limit] = 50 unless params[:limit]
        
        search_options = {:offset => params[:start], :limit => params[:limit]}
        search_options.merge!(:order => params[:sort].blank? ? "created_at DESC" : "#{params[:sort]} #{params[:dir]}") 
    
        query_params = params[:q]
        unless query_params.blank? 
          query_params = query_params.split(/\s+/)
          query_params = query_params.map {|q| q+"*"}.join(" ")
        end
        
        @profile_requests = current_account.profile_requests.search(query_params, search_options)
        @profile_requests_count = current_account.profile_requests.count_results(query_params)
        
        render :json => {:collection => self.assemble_records(@profile_requests), :total => @profile_requests_count}.to_json
      end
    end
  end
  
  def edit
    
  end
  
  def approve_collection
    @approved_items_size = 0
    @unapproved_items_size = 0
    @claimed_items_size = 0
    current_account.profile_requests.find(params[:ids].split(",").map(&:strip).reject(&:blank?)).each do |req|
      if req.profile && req.profile.claimed?
        @claimed_items_size += 1
        next
      else
        if req.approve!
          @approved_items_size += 1
        else
          @unapproved_items_size += 1
        end
      end
    end

    error_message = []
    error_message << "#{@approved_items_size} profile request(s) successfully approved" if @approved_items_size > 0
    error_message << "#{@unapproved_items_size} profile request(s) failed to be approved" if @unapproved_items_size > 0
    error_message << "#{@claimed_items_size} profile(s) were already claimed" if @claimed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js
    end
  end
  
  def destroy_collection
    destroyed_items_size = 0
    current_account.profile_requests.find(params[:ids].split(",").map(&:strip)).to_a.each do |req|
      destroyed_items_size += 1 if req.destroy
    end

    flash_success :now, "#{destroyed_items_size} profile request(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end
  
  def create_claim
    @avatar = params[:profile].delete("avatar")

    flash[:liquid] ||= {}
    flash[:liquid][:params] = params
    
    @profile = current_account.profiles.find(params[:profile_id])

    begin
      if @profile.claimed?
        raise "Sorry, this profile has already been claimed"
      elsif params[:profile][:email].blank? || params[:profile][:email][:main].blank? || params[:profile][:email][:main][:email_address].blank?
        raise "Email can't be blank"
      elsif Party.find_by_account_and_email_address(current_account, params[:profile][:email][:main][:email_address]) && !@profile.party.email_addresses.map(&:email_address).include?(params[:profile][:email][:main][:email_address])
        raise "Email has already been taken"
      end
      @email = params[:profile].delete("email")
      @phone = params[:profile].delete("phone")
      @link = params[:profile].delete("link")
      @address = params[:profile].delete("address")
      @group_labels = params[:profile].delete(:group_labels)
      @profile_claim_request = current_account.profile_claim_requests.build(params[:profile])
      
      # Attaching current domain id to the profile claim request
      @profile_claim_request.domain_id = self.current_domain.id
      
      self.process_request(@profile_claim_request, params) 
      @profile_claim_request.created_by = current_user if current_user?
      @profile_claim_request.profile = @profile
      
      @profile_claim_request.email = @email unless @email.blank?
      confirmation_url = params[:confirm_url].blank? ? "/profiles/confirm?id=__ID__&code=__CODE__" : params[:confirm_url]
     
      @party = @profile.party
      @party.confirmation_token = UUID.random_create.to_s if @profile.party.confirmation_token.blank? 
      @party.confirmation_token_expires_at = @party.account.get_config(:confirmation_token_duration_in_seconds).from_now
      @party.save!
      
      @profile_claim_request.confirmation_url = "http://#{current_domain.name}" + confirmation_url.gsub("__ID__", @profile.id.to_s).gsub("__CODE__", @party.reload.confirmation_token)
      
      @profile_claim_request.save!
      email_address = @profile_claim_request.main_email.email_address
      if !current_domain.get_config("profile_request_moderation") || current_user.can?(:edit_profile_requests)
        @profile_claim_request.approve!
        flash_success params[:approved_message] ? params[:approved_message].gsub("__email__", email_address) : "Thank you, please check your email at #{email_address} to finish claiming the profile."
      else
        flash_success params[:success_message] ? params[:sucess_message].gsub("__email__", email_address) : "Thank you, your claim request is pending approval by an Admin. You will receive an email at #{email_address} when the request is approved"
      end
      
      respond_to do |format|
        format.html do
          return redirect_to_next_or_back_or_home
        end
        format.js do
          render :json => {:success => true, :message => flash[:notice].join(", ")}
        end
      end
    rescue
      flash_failure $!.message
      logger.debug($!.message)
      logger.warn($!.backtrace.join("\n"))
      respond_to do |format|
        format.html do
          return redirect_to_return_to_or_back_or_home
        end
        format.js do
          render :json => {:success => false, :message => $!.message}
        end
      end
    end
  end
  
  def create_add
    @avatar = params[:profile].delete("avatar")

    flash[:liquid] ||= {}
    flash[:liquid][:params] = params
    begin
      if params[:profile][:email].blank? || params[:profile][:email][:main].blank? || params[:profile][:email][:main][:email_address].blank?
        params[:profile].delete("email")
      elsif Party.find_by_account_and_email_address(current_account, params[:profile][:email][:main][:email_address])
        raise "Email has already been taken"
      end
      
      @email = params[:profile].delete("email")
      @phone = params[:profile].delete("phone")
      @link = params[:profile].delete("link")
      @address = params[:profile].delete("address")
      @group_labels = params[:profile].delete(:group_labels)
      
      @profile_add_request = current_account.profile_add_requests.create!(params[:profile])
      
      self.process_request(@profile_add_request, params) 
      @profile_add_request.created_by = current_user if current_user?
      @profile_add_request.email = @email unless @email.blank?
      
      @profile_add_request.save!
      
      if params[:comment] && !params[:comment][:body].blank?
        params[:comment].merge!(:rating => params[:rating]) unless params[:rating].blank?
        @comment = current_account.comments.build(params[:comment])
        @comment.commentable = @profile_add_request
        @comment.domain = current_domain
        
        @comment.user_agent = request.env["HTTP_USER_AGENT"]
        @comment.referrer_url = request.env["HTTP_REFERER"]
        @comment.request_ip = request.remote_ip
        @comment.created_by = @comment.updated_by = current_user if current_user?
        @comment.spam = false
        @comment.approved_at = Time.now
        @comment.save
      end
        
      if !current_domain.get_config("profile_request_moderation") || current_user.can?(:edit_profile_requests)
        @profile_add_request.approve!
        flash_success params[:approved_message] || "Thank you, your profile has been approved"
      else
        flash_success params[:success_message] || "Thank you, your profile will be published upon approval"
      end
      
      respond_to do |format|
        format.html do
          return redirect_to_next_or_back_or_home
        end
        format.js do
          render :json => {:success => true, :message => flash[:notice].join(", ")}
        end
      end
    rescue
      flash_failure $!.message
      logger.debug($!.message)
      logger.warn($!.backtrace.join("\n"))
      respond_to do |format|
        format.html do
          return redirect_to_return_to_or_back_or_home
        end
        format.js do
          render :json => {:success => false, :message => $!.message}
        end
      end
    end
  end
  
  protected
  def assemble_records(records)
    results = []
    records.each do |record|
      results << truncate_record(record)
    end
    results
  end
  
  def truncate_record(record)
    timestamp_format = "%d/%m/%Y"
    view_profile = (record.profile && record.profile.party) ? "<a href='#' onclick='xl.openNewTabPanel(\"profiles_edit_#{record.profile_id}\", \"/admin/profiles/#{record.profile.party.id}/edit\")'>View</a>" : ""
    info = record.info.blank? ? "" : record.info.map{|k,v|"#{k.to_s}: #{v.to_s}<br />"}.join(" ")
    {
      :id => record.id,
      :name => [record.first_name, record.middle_name, record.last_name].join(" "),
      :company_name => record.company_name,
      :avatar_url => record.avatar.blank? ? "" : record.avatar.src,
      :info => info,
      :created_at => record.created_at.strftime(timestamp_format),
      :approved_at => record.approved_at ? record.approved_at.strftime(timestamp_format) : (record.type =~ /ProfileClaimRequest/i && record.profile && record.profile.claimed? ? "Already Claimed" : ""),
      :created_by_id => record.created_by_id,
      :created_by_name => record.created_by ? record.created_by.display_name : "",
      :profile_id => record.profile_id,
      :links => record.links.map(&:url).join(", "),
      :phones => record.phones.map(&:number).join(", "),
      :emails => record.email_addresses.map(&:email_address).join(", "),
      :tag_list => record.tag_list, 
      :addresses => record.addresses.map {|addr| addr.to_formatted_s(:html => {:tag => "p", :class => "other-address"}) }.join(""), 
      :view_profile => view_profile,
      :groups => record.group_ids.blank? ? "" : current_account.groups.all(:conditions => ["id IN (?)", record.group_ids.split(",")]).map(&:name).join(", "),
      :type => case record.type
                when /ProfileClaimRequest/i
                  "Claim"
                when /ProfileAddRequest/i
                  "Add"
                end
    }
  end
  
  def process_request(request, params)
      unless @avatar.blank? || @avatar.size == 0 then
        @avatar = request.build_avatar(:uploaded_data => @avatar, :account => current_account)
        @avatar.save!
      end      
      if @group_labels
        groups = current_account.groups.find(:all, :conditions => {:label => @group_labels.split(",").map(&:strip).reject(&:blank?)})
        request.group_ids = groups.map(&:id).join(",") unless groups.empty?
      end
      request.save
      request.reload
      request.phone = @phone unless @phone.blank?
      request.address = @address unless @address.blank?
      if @link
        @link.each_pair do |key, value|
          unless value[:url].blank? || value[:name] =~ /^name$/i || value[:url] =~ /^http:\/\/\s*$/i
            link = request.links.build(value)
            link.save!
          end
        end
      end
      
      profile_alias = params[:profile].delete("forum_alias")
      profile_alias = params[:profile][:alias] if params[:profile][:alias]
      params[:profile][:alias] = profile_alias
      
      request.alias = profile_alias.blank? ? nil : profile_alias
  end
end
