#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class ProfilesController < ApplicationController
  # check authorized? overwrite
  required_permissions :none
  before_filter :load_profile, :only => %w(update destroy confirm validate_forum_alias validate_alias)

  def create
    confirmation_url_builder = lambda {|party, code|
      base_url = params[:confirm_url].blank? ? "/profiles/confirm?id=__ID__&code=__CODE__" : params[:confirm_url]

      uri = URI.parse(base_url)
      unless uri.absolute? then
        uri.scheme = "http"
        uri.host = current_domain.name
        uri.query = uri.query.sub("__ID__", party.profile.id.to_s).sub("__CODE__", code)
        uri.port = nil
      end
      uri.to_s
    }

    # TODO: please modify this later on, should we move this inside the Party.signup! maybe
    # BUT they might not be signing up for profile at all...
    params[:profile] ||= {}
    party_params = params[:profile].dup
    party_params.symbolize_keys!
    params[:profile].delete(:group_labels)
    params[:profile].delete(:group_ids)
    ActiveRecord::Base.transaction do
      @profile = current_account.profiles.build(params[:profile])
      @profile.current_domain = current_domain
      @profile.save!
      if party_params[:group_labels]
        groups = current_account.groups.find(:all, :select => "groups.id", :conditions => {:label => party_params.delete(:group_labels).split(",").map(&:strip).reject(&:blank?)})
        party_params[:group_ids] = groups.map(&:id).join(",") unless groups.empty?
      end
      @party = current_account.parties.signup!(:domain => current_domain, :email_address => {:email_address => params[:email_address]}, :group_ids => party_params.delete(:group_ids), :party => party_params,
          :confirmation_url => confirmation_url_builder, :profile => @profile)
      @party.copy_contact_routes_to_profile!
    end

    redirect_to((params[:next] || "/profiles/signup").sub("__ID__", @profile.id.to_s))
  rescue
    logger.info {"==> profiles\#create:  #{$!}"}
    logger.debug {$!.backtrace.join("\n")}

    flash_failure "Email address already taken"

    flash[:liquid] ||= {}
    flash[:liquid][:profiles] ||= {}
    flash[:liquid][:profiles][:email_address] = params[:email_address]
    flash[:liquid][:profiles][:party] = params[:party]

    redirect_to(params[:return_to] || request.env["HTTP_REFERER"] || "/profiles/new")
  end

  # TODO: I DON'T THINK WE ARE USING THIS ARE WE? WE SHOULD USE SESSIONS CONTROLLER FOR THIS
  def login
    self.current_user = Party.authenticate_with_account_email_and_password!(
        current_account, params[:email_address], params[:password])
    cookies[XlSuite::AuthenticatedSystem::AUTH_TOKEN] = self.current_user.remember_me! if "1" == params[:remember_me]
    redirect_to(params[:next] || request.env["HTTP_REFERER"] || "/profiles/edit")

  rescue
    logger.info {"==> profiles\#login:  #{$!}"}
    logger.debug {$!.backtrace.join("\n")}

    flash_failure "Invalid credentials"

    flash[:liquid] ||= {}
    flash[:liquid][:profiles] ||= {}
    flash[:liquid][:profiles][:email_address] = params[:email_address]
    
    redirect_to(params[:return_to] || request.env["HTTP_REFERER"] || "/profiles/new")
  end
  
  def create_profile_from_party
    @profile = current_account.profiles.build
    if params[:copy_info]
      @profile = @party.to_new_profile
    end
    @profile.current_domain = current_domain
    @profile.save!
    @party.profile = @profile
    @party.save!
    if params[:copy_routes]
      @party.copy_contact_routes_to_profile!
    end
    respond_to do |format|
      format.js do
        return render(:json => {:success => true}.to_json)
      end
    end
    rescue 
      respond_to do |format|
        format.js do
          return render(:json => {:success => false}.to_json)
        end
      end
  end
  
  def edit
    @formatted_comments_path = formatted_comments_path(:commentable_type => "Profile", :commentable_id => @profile.id, :format => :json) if @profile
    @edit_comment_path = edit_comment_path(:commentable_type => "Profile", :commentable_id => @profile.id, :id => "__ID__") if @profile
    respond_to do |format|
      format.js
    end
  end
  
  def update
    respond_to do |format|
      format.html do
        begin
          ActiveRecord::Base.transaction do
            save_party_fields(params)
            
            # Only authenticate if we aren't editing ourselves
            @profile.party.attempt_password_authentication!(params[:profile][:password]) unless (@profile.password_hash.blank? || @profile.party == current_user)
            @profile.update_attributes!(params[:profile])
          end

          return redirect_to((params[:next] || "/profiles/view?id=__ID__").sub("__ID__", @profile.id.to_s))
        rescue
          %w(addresses phones links email_addresses).each do |method|
            @profile.send(method).each do |model|
              next if model.valid?
              logger.debug {"#{model.class.name} (#{model.id}/#{model.name}): #{model.errors.full_messages}"}
            end
          end

          logger.info {"==> profiles\#update:  #{$!}"}
          logger.debug {$!.backtrace.join("\n")}

          flash_failure "Error saving data: #{$!}"

          flash[:liquid] ||= {}
          flash[:liquid][:profile] = params[:profile]
          flash[:liquid][:profile].delete(:avatar) # Can't store that in the session

          return redirect_to(params[:return_to] || request.env["HTTP_REFERER"] || "/profiles/new")
        end
      end
      format.js do
        if params[:profile]
          if params[:profile][:deactivate_commenting_on]
            if params[:profile][:deactivate_commenting_on] == "false"
              @profile.update_attribute("deactivate_commenting_on", nil) 
            else
              @profile.update_attribute("deactivate_commenting_on", params[:profile][:deactivate_commenting_on] )
            end
          end
          params[:profile].delete(:deactivate_commenting_on)

          @profile.attributes = params[:profile]
          @profile.hide_comments = (params[:profile][:hide_comments]=="false") ? false : true unless params[:profile][:hide_comments].blank?
          
          @updated = @profile.save
        end
        return render_json_response
      end
    end
  end
  
  def confirm
    respond_to do |format|
      format.html do
        begin
          ActiveRecord::Base.transaction do
            save_party_fields(params)
            
            @profile.party.authorize!(:attributes => {:password => params[:profile].delete(:password), :password_confirmation => params[:profile].delete(:password_confirmation)}, 
                                      :confirmation_token => params[:profile].delete(:confirmation_code))
            @profile.update_attributes!(params[:profile])
            
            # must go after update_attributes! since if that fails (mainly password != password_confirmation token), 
            # we shouldn't log the user in
            self.current_user = @profile.party unless current_user? # Don't login unless we were anonymous
          end

          return redirect_to((params[:next] || "/profiles/view?id=__ID__").sub("__ID__", @profile.id.to_s))
        rescue
          %w(addresses phones links email_addresses).each do |method|
            @profile.send(method).each do |model|
              next if model.valid?
              logger.debug {"#{model.class.name} (#{model.id}/#{model.name}): #{model.errors.full_messages}"}
            end
          end

          logger.info {"==> profiles\#update:  #{$!}"}
          logger.debug {$!.backtrace.join("\n")}

          flash_failure "Error saving data: #{$!}"

          flash[:liquid] ||= {}
          flash[:liquid][:profile] = params[:profile]
          flash[:liquid][:profile].delete(:avatar) # Can't store that in the session

          return redirect_to(params[:return_to] || request.env["HTTP_REFERER"] || "/profiles/new")
        end
      end
    end
  end
  
  def validate_feed
    @feed_error = "is valid"
    logger.debug("^^^#{params.inspect}")
    existing_feed = current_account.feeds.find_by_label(params[:label])
    if params[:party_id]
      @profile = current_account.parties.find(params[:party_id])
      @feed_error = "Feed title already taken" if existing_feed && !@profile.feeds.include?(existing_feed)
    else
      @feed_error = "Feed title already taken" if existing_feed
    end

    render :layout => false
  end

  def validate_forum_alias
    @profile.alias = params[:q]
    @profile.valid? # We just want to run validation

    if @profile.errors.on(:alias) then
      @forum_alias_error = "Username already taken"
    else
      @forum_alias_error = "Is valid"
    end

    render :template => "profiles/validate_forum_alias", :layout => false
  end
  alias_method  :validate_alias, :validate_forum_alias
  
  def show_feed
    @profile = current_account.parties.find(params[:id])
    @feed = @profile.feeds.find(params[:feed])
    if !@feed.refreshed_at
      @feed.refresh
    end
    respond_to do |format|
      format.js
    end
  end
  
  def auto_complete_city
    profile_ids = current_account.profiles.map(&:id)
    @city_fields = current_account.address_contact_routes.find(:all, 
        :conditions => ["routable_id IN (#{profile_ids.join(",")}) AND routable_type = 'Profile' AND city LIKE ?", "%"+params[:city]+"%"], 
        :order => "city ASC") unless profile_ids.blank?
    
    render :inline => "<%= auto_complete_result(@city_fields, 'city') %>"
  end
  
  def auto_complete_state
    profile_ids = current_account.profiles.map(&:id)
    @state_fields = current_account.address_contact_routes.find(:all, 
        :conditions => ["routable_id IN (#{profile_ids.join(",")}) AND routable_type = 'Profile' AND state LIKE ?", "%"+params[:state]+"%"], 
        :order => "state ASC") unless profile_ids.blank?
    
    render :inline => "<%= auto_complete_result(@state_fields, 'state') %>"
  end
  
  protected
  def save_party_fields(params)
    unless params[:profile][:avatar].blank? || params[:profile][:avatar].size == 0 then
      @profile.avatar.destroy if @profile.avatar
      avatar = @profile.build_avatar(:uploaded_data => params[:profile].delete(:avatar), :account => @profile.account)
      avatar.crop_resized("70x108")
      avatar.save!
      #need to save now, or else it loses the link to the avatar when we do a @profile.reload below
      @profile.save!
    else
      params[:profile].delete("avatar")
    end

    if params[:profile].has_key?("link") 
      @profile.links.each{ |link| link.destroy }
      params[:profile][:link].each_pair do |key, value|
        unless value[:url].blank? || value[:name] =~ /^name$/i || value[:url] =~ /^http:\/\/\s*$/i
          link = @profile.links.build(value)
          link.save!
        end
      end
      params[:profile].delete(:link)
    end
    
    params[:info][:title].each_pair do |key, value|
      if value.blank?
        params[:info][:title].delete(key)
        params[:info][:body].delete(key)
      elsif params[:info][:body][key].nil?
        params[:info][:title].delete(key)
      else
        params[:info][:body][key] = params[:info][:body][key].slice(0, 2000)
      end
    end if params[:info] && params[:info][:title] && params[:info][:body]

    #this may need to change in the future, since feeds are shared between parties
    if params[:feed] then
      @profile.party.feeds.each { |feed| feed.destroy }
      params[:feed].each_pair do |key, value|
        unless value[:url].blank?
          feed = current_account.feeds.build(value)
          feed.created_by = @profile.party
          feed.save!
          @profile.party.feeds << feed
        end
      end 
      @profile.party.feeds.each do |feed|
        if feed.refreshed_at > 5.years.ago
          MethodCallbackFuture.create!(:models => [feed], :account => @profile.account, :method => :refresh)
        end
      end
    end

    @profile.info = params[:info] if params[:info]

    profile_alias = params[:profile].delete("forum_alias")
    profile_alias = params[:profile][:alias] if params[:profile][:alias]
    params[:profile][:alias] = profile_alias
    
    @profile.alias = profile_alias.blank? ? nil : profile_alias

    if params[:files].kind_of?(Hash)
      params[:files].each_pair do |key, value|
        asset = current_account.assets.build(value)
        asset.owner = @profile.party
        created = asset.save
        if created
          View.create(:asset => asset, :attachable => @profile.party)
        end
      end
    end
  end

  def load_profile
    @profile = current_account.profiles.find(params[:id])
  end
  
  def load_party_profile
    @party = current_account.parties.find(params[:id])
    @profile = @party.profile
  end

  def render_json_response
    errors = (@profile.errors.full_messages.blank? ? ($! ? $!.message : "")  : render_to_string(:partial => "/shared/error_messages_for", :locals => {:symbol => :blog})).to_s
    render :json => {:flash => flash[:notice].to_s, :close => @updated && @close, :errors => errors, 
                     :id => @profile.id, :success => @updated || @created }.to_json
  end
  
  def authorized?
    case self.action_name
    when /\A(edit|create_profile_from_party|)\Z/i
      return false unless self.current_user?
      self.load_party_profile
      return true if self.current_user.can?(:edit_profiles)
      return true if self.current_user == @party
      false
    when /\A(login|create|confirm|validate_forum_alias|validate_alias)\Z/i
      true
    else
      self.current_user?
    end
  end
end
