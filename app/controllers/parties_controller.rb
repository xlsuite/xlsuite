#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class PartiesController < ApplicationController
  required_permissions %w(change_password edit effective_permissions async_get_tag_name_id_hashes show network general profile tags security notes staff testimonials 
          update refresh_inbox send_new_password images multimedia other_files) => [:edit_party, :edit_own_account, :edit_own_contacts_only, {:any => true}],
      %w(import import_load plaxo address_book auto_complete new create destroy archive destroy_collection reset_collection_password tagged_collection 
          add_collection_to_group publish_profiles create_from_email_addresses) => [:edit_party, :edit_own_contacts_only, {:any => true}],
      %w(index) => [:edit_party, :edit_own_contacts_only, :view_own_contacts_only, :view_party, {:any => true}],
      %w(update_feeds forgot_password reset_password register signup confirm authorize subscribe extjs_auto_complete) => true
  before_filter :load_party, :except => %w(index auto_complete forgot_password reset_password new create create_from_email_addresses import_load import plaxo address_book register signup 
       confirm destroy_collection reset_collection_password tagged_collection add_collection_to_group publish_profiles extjs_auto_complete)
  before_filter :check_own_access, :except => %w(index auto_complete forgot_password reset_password plaxo address_book register signup confirm authorize subscribe extjs_auto_complete)
  before_filter :keep_whitelisted_parameters_if_unauthorized, :only => %w(update authorize signup)
  before_filter :find_common_party_tags, :only => %w(new create edit show general tags security)
  before_filter :load_groups, :only => %w( index general network notes profile security staff tags testimonials )
  before_filter :set_routes_instance_variables, :only => %w( general profile tags notes security network staff testimonials)
  
  before_filter :set_certain_parameters_to_nil, :only => %w(update)

  skip_before_filter :login_required, :only => %w(register signup confirm authorize subscribe)
  skip_before_filter :reject_unconfirmed_user, :except => %w(register signup)

  layout :choose_layout

  helper :tabs, :contact_routes

  ItemsPerPage = 10

  def index
    @title = "Contact List"
    @default_search = params[:default_search]
    respond_to do |format|
      format.html do
        self.find_parties
      end
      format.js
      format.xml do
        self.find_parties
        render(:text => @parties.to_xml.sub("<parties>", "<parties total='#{@parties_count}'>"))
      end
      format.json do
        process_index
        render :json => {:collection => assemble_records(@parties), :total => @parties_count}.to_json
      end
    end
  end

  def async_get_tag_name_id_hashes
    tags = Tag.find :all, :order => "name"
    name_ids = []
    name_ids += [{ 'name' => 'New Tag', 'id' => params[:with_new_tag] }] if params[:with_new_tag]
    name_ids += tags.collect { |tag| { 'name' => tag.name, 'id' =>  tag.id.to_s } }

    # [{name: "New Tag", id: "-1"}, {name: "Access", id: "5"}, {name: "Admins", id: "6"}, {name: "Adminx2", id: "37"}]
    wrapper = {'total' => name_ids.size, 'collection' => name_ids}
    render :json => wrapper.to_json, :layout => false
  end

  def auto_complete
    @q = params[:q]
    self.find_parties
    render :layout => false
  end

  def forgot_password
    @email = EmailContactRoute.new
    render_within_public_layout
  end

  def reset_password
    @party = current_account.parties.find(:first, :select => "parties.*",
        :joins => "INNER JOIN contact_routes ON contact_routes.routable_type = 'Party' AND contact_routes.routable_id = parties.id",
        :conditions => ["contact_routes.type = ? AND contact_routes.email_address = ?", EmailContactRoute.name, params[:email][:email_address]])
    raise ActiveRecord::RecordNotFound unless @party
    
    if @party.confirmed?
      @party.reset_password(current_domain.name)

      flash_success "Your password has been reset"
    else
      Party.transaction do
        @party.confirmation_token_expires_at = 24.hours.from_now
        @party.confirmation_token ||= UUID.random_create.to_s
        @party.save!
        AdminMailer.deliver_signup_confirmation_email(:route => @party.main_email(true),
            :confirmation_url => lambda {|party, code| confirm_party_url(:id => @party, :code => code)},
            :confirmation_token => @party.confirmation_token)
      end
      flash_success "You have not confirmed your account. A confirmation email has been sent to your email, please check your email and spam folder."
    end
    
    redirect_to new_session_path

    rescue
      logger.warn $!.message
      logger.warn $!.backtrace.join("\n")
      flash_failure :now, "This account does not exist in our database."
      render :action => "forgot_password"
  end

  def new
    @party = Party.new
    if params[:id]
      base_party = current_account.parties.find(params[:id])
      @party = Party.new_party_from(base_party)
      @title = "Duplicating #{base_party.display_name}"
      @party.addresses.build(:name => "Main") if @party.addresses.blank?
      @party.email_addresses.build(:name => "Main")
      @party.links.build(:name => "Blog")
      @party.links.build(:name => "Company")
      @party.phones.build(:name => "Office")
      @party.phones.build(:name => "Mobile")
      @_tag_list = base_party.tag_list
    else
      @party.addresses.build(:name => "Main")
      @party.email_addresses.build(:name => "Main")
      @party.links.build(:name => "Blog")
      @party.links.build(:name => "Company")
      @party.phones.build(:name => "Office")
      @party.phones.build(:name => "Mobile")
    end
    logger.debug("====> #{@party.attributes.inspect}")
    @force_editor = true
  end

  def archive
    if @party == current_user then
      flash_failure "You cannot archive your own record."
      return redirect_to(party_path(@party))
    end

    @party.archive
    flash_success "#{@party.name.to_forward_s} was archived."
    respond_to do |format|
      format.html { redirect_to parties_path }
      format.js { render :action => "destroy.rjs" }
    end
  end

  def show
    redirect_to general_party_path(@party)
  end

  def general
    render :action => "tags"
  end

  def profile
    respond_to do |format|
      format.html
      format.js { render :action => "profile", :layout => false }
    end
  end

  def tags
    respond_to do |format|
      format.html
      format.js { render :action => "tags", :layout => false }
    end
  end

  def notes
    @force_editor = @party.new_record? || @party.notes.blank?
    respond_to do |format|
      format.html
      format.js { render :action => "notes", :layout => false }
    end
  end

  def security
    if current_user.can?(:edit_party_security) then
      @available_groups = current_account.groups.find_all_roots(current_account)
      @available_permissions = Permission.find(:all, :order => "name")
    else
      @available_groups = @available_permissions = []
    end
    respond_to do |format|
      format.html
      format.js { render :action => "security", :layout => false }
    end
  end

  def network
    respond_to do |format|
      format.html
      format.js { render :action => "network", :layout => false }
    end
  end

  def staff
    respond_to do |format|
      format.html
      format.js { render :action => "staff", :layout => false }
    end
  end

  def testimonials
    respond_to do |format|
      format.html
      format.js { render :action => "testimonials", :layout => false }
    end
  end

  def update_feeds
    @party.feeds.clear
    @party.update_attributes(params[:party])
    render :update do |page|
      page << "parent.myFeedsShow();"
    end
  end

  def create
    # Don't record tags Tag and List, as these are automatically added by the XlSuite::InlineFormBuilder
    params[:party][:tag_list].gsub!("Tag List", "") if params[:party] && params[:party][:tag_list]

    @party = current_account.parties.build(params[:party])
    @party.created_by = @party.updated_by = current_user
    Party.transaction do
      if @party.affiliate_usernames.blank? && session[AFFILIATE_IDS_SESSION_KEY]
        @party.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
      end
      @party.save!

      {:address => nil, :phone => :number, :link => :url, :email_address => :email_address}.each_pair do |model_type, main_attribute|
        params[model_type].each_pair do |id, attributes|
          next if attributes.empty?
          next if attributes.size == 1 && attributes.has_key?(:name) && main_attribute.nil?
          next if main_attribute && attributes[main_attribute].blank?
          klass_name = "#{model_type.to_s.split('_').first}_contact_route"
          klass = klass_name.classify.constantize
          instance_variable_set("@#{model_type}".to_sym, klass.new(attributes.merge(:routable => @party)))
          variable = instance_variable_get("@#{model_type}".to_sym)
          variable.save!
        end unless params[model_type].blank?
      end

      respond_to do |format|
        format.html do 
          responds_to_parent do 
            render :update do |page|
              page << %Q`xl.closeTabs("/admin/parties/new")`
              page << %Q`xl.openNewTabPanel('parties_edit_#{@party.id}',#{edit_party_path(@party).to_json})`
            end
          end
        end
      end
    end

    rescue
      find_common_party_tags
      flash_failure :now, $!.message
      @party = current_account.parties.build(params[:party])
      {:address => nil, :phone => :number, :link => :url, :email_address => :email_address}.each_pair do |model_type, main_attribute|
        params[model_type].each_pair do |id, attributes|
          self.instance_variable_set("@#{model_type}".to_sym, @party.send(model_type.to_s.pluralize.downcase).build(attributes.merge(:routable => @party)) )
          variable = instance_variable_get("@#{model_type}".to_sym)
          next if attributes.empty?
          next if attributes.size == 1 && attributes.has_key?(:name) && main_attribute.nil?
          next if main_attribute && attributes[main_attribute].blank?
          variable.valid?
          variable.errors.instance_variable_get(:@errors).delete("routable_id")
        end
      end
      @force_editor = true
      render :action => "new", :layout => "new-party"
  end
  
  def create_from_email_addresses
    ids = []
    party = nil
    names = []
    if params[:names]
      params[:names].split(",").map(&:strip).each do |name|
        names << ((name =~ EmailContactRoute::ValidAddressRegexp) ? "" : name)
      end
    end
    params[:email_addresses].split(",").map(&:strip).each_with_index do |email_address, index|
      party = Party.find_by_account_and_email_address(self.current_account, email_address)
      if party
        ids << party.id 
        next
      end
      ActiveRecord::Base.transaction do
        party = self.current_account.parties.create!(:name => Name.parse(names[index] || ""))
        EmailContactRoute.create!(:account => self.current_account, :routable => party,
          :email_address => email_address, :name => "Main")
        ids << party.id
      end
    end
    respond_to do |format|
      format.js do
        render(:json => {:ids => ids}.to_json)
      end
    end
  end

  def edit
    @formatted_total_group_permission_grants_path = formatted_permission_grants_path(:format => "json", :mode => "total", :assignee_type => "Group", :assignee_id => "__ID__")
    @formatted_total_role_permission_grants_path = formatted_permission_grants_path(:format => "json", :mode => "total", :assignee_type => "Role", :assignee_id => "__ID__")
    @formatted_selected_permissions_path = formatted_permission_grants_path(:format => "json", :assignee_type => "Party", :assignee_id => @party.id, :include_selected => true)
    
    @permission_grants_path = permission_grants_path(:assignee_type => "Party", :assignee_id => @party.id)
    @destroy_collection_permission_grants_path = destroy_collection_permission_grants_path(:assignee_type => "Party", :assignee_id => @party.id)
    
    @formatted_permission_denials_path = formatted_permission_denials_path(:assignee_id => @party.id, :assignee_type => "Party", :format => "json")
    @permission_denials_path = permission_denials_path(:assignee_type => "Party", :assignee_id => @party.id)
    @destroy_collection_permission_denials_path = destroy_collection_permission_denials_path(:assignee_type => "Party", :assignee_id => @party.id)
    
    @imap_account = @party.own_imap_account? ? @party.own_imap_account : ImapEmailAccount.new
    
    @disable_share_imap = true
    if self.current_user.id == @party.id
      @disable_share_imap = true
    else
      @disable_share_imap = !self.current_user.own_imap_account?
    end
    @current_user_imap_account = self.current_user.own_imap_account? ? self.current_user.own_imap_account : ImapEmailAccount.new
    
    @smtp_account = @party.own_smtp_account? ? @party.own_smtp_account : SmtpEmailAccount.new
    @disable_share_smtp = true
    if self.current_user.id == @party.id
      @disable_share_smtp = true
    else
      @disable_share_smtp = !self.current_user.own_smtp_account?
    end
    @current_user_smtp_account = self.current_user.own_smtp_account? ? self.current_user.own_smtp_account : SmtpEmailAccount.new
    
    respond_to do |format|
      format.js
    end
  end

  def update
    begin
      both_password_field_blank = params[:party][:password].blank? && params[:party][:password_confirmation].blank?
      if both_password_field_blank then
        params[:party].delete(:password)
        params[:party].delete(:password_confirmation)
      elsif params[:commit] =~ /change/i
        @party.change_password!(:old_password => params[:party].delete(:old_password),
                                :password => params[:party].delete(:password),
                                :password_confirmation => params[:party].delete(:password_confirmation))
        flash_success "Password successfully changed"
        params[:party].delete(:denied_permission_ids)
      end
      
      if params[:party][:info] && @party.info
        @party.info.each_pair do |key, value|
          unless params[:party][:info][key]
            params[:party][:info][key] = (value || {})
          end
        end
      end

      Party.transaction do
        @party.update_attributes!(params[:party].merge(:updated_by => current_user))
        @attribute = params[:party].keys.first
        respond_to do |format|
          format.html { redirect_to party_path(@party) }
          format.js
        end
      end

    rescue ActiveRecord::RecordInvalid, XlSuite::AuthenticatedUser::BadAuthentication
      logger.debug {"#{$!.message}\n#{$!.backtrace.join("\n")}"}
      load_groups
      respond_to do |format|
        format.html { render :action => :security }
        format.js do
          render :update => true do |page|
            page.alert("Your old password does not match")
          end
        end
      end
    end
  end

  def change_password
    if params[:reset]
      @party.reset_password(current_domain.name)
      respond_to do |format|
        format.js do
          return render(:json => {:success => true, :popup_messages => %Q`<p>The password for <b>#{@party.name.to_s.upcase}</b> has been reset.</p><p>An email containing the new password has been sent to #{@party.main_email.email_address}</p>`}.to_json)
        end
      end
    else
      begin
        @party.change_password!(:old_password => params.delete(:old_password),
                               :password => params.delete(:password),
                               :password_confirmation => params.delete(:password_confirmation))
        respond_to do |format|
          format.js do
            return render(:json => {:success => true, :popup_messages => "Password successfully changed"}.to_json)
          end
        end
      rescue XlSuite::AuthenticatedUser::BadAuthentication
        respond_to do |format|
          format.js do
            return render(:json => {:success => false, :popup_messages => "Password change failed"}.to_json)
          end
        end
      end
    end
  end

  def destroy
    if current_user == @party then
      flash_failure "You cannot destroy your own account"
      return redirect_to(party_path(@party))
    end

    @party.destroy
    flash_success "Contact successfully removed"
    respond_to do |format|
      format.html { redirect_to parties_path }
      format.js
    end
  end

  def plaxo
  end

  def address_book
    render :layout => false
  end

  def import
    @tag_list = current_account.tags.parse('import')
    @format_type = [["Card Scanner", 1], ["Lighting Companies", 2], ["NorthVan Restaurants", 3],
                    ["Vancouver Sign Companies", 4], ["NorthVan Car Dealerships", 5], ["BIA Contacts", 6]]
  end

  def import_load
    return unless request.post?
    @tag_list = current_account.tags.parse(params[:tag_list])
    import_num = -2
    errors = []

    # FIXME: Temporary solution !  We must find a way to tell the PartyImporter
    # that we are importing with a parent object in mind
    Party.with_scope(
        :find => {:conditions => ["parties.account_id = ?", current_account.id]},
        :create => {:account => current_account}) do
      if params[:format_type] == "1"
        import_num, errors = PartyImporter.card_scanner_import(params[:file], @tag_list)
      elsif params[:format_type] == "2"
        import_num, errors = PartyImporter.lighting_companies_import(params[:file], @tag_list)
      elsif params[:format_type] == "3"
        import_num, errors = PartyImporter.northvan_restaurants_import(params[:file], @tag_list)
      elsif params[:format_type] == "4"
        import_num, errors = PartyImporter.vancouver_sign_companies_import(params[:file], @tag_list)
      elsif params[:format_type] == "5"
        import_num, errors = PartyImporter.northvan_car_dealerships_import(params[:file], @tag_list)
      elsif params[:format_type] == "6"
        import_num, errors = PartyImporter.bia_contacts_import(params[:file], @tag_list)
      end
    end

    if import_num == -1
      flash[:notice] = "File format invalid"
    elsif import_num == -2
      flash[:notice] = "Format not supported"
    else
      text = []
      text << "#{import_num} contacts were successfully imported"
      if !errors.blank?
        text << "#{errors.size} errors were encountered."
        text << "Failed to insert contacts from the following rows: #{errors.join(' ')}"
      end
      flash[:notice] = text
    end

    redirect_to :action => "index"
  end

  def register
    @party = Party.new
    @email_address = EmailContactRoute.new
    render_within_public_layout
  end

  # Params:
  # return_to: path to return to if an error occurs
  # signed_up: path to go to when a user is successfully signs up
  # next: path to go to when an email has to be sent out to the user
  def signup
    params[:party] ||= {}
    if params[:party][:group_labels]
      params[:party][:group_labels] = params[:party][:group_labels].split(",") if params[:party][:group_labels].is_a?(String)
      # Flatten array such as ["lead", "news, local_news"]
      params[:party][:group_labels] = params[:party][:group_labels].join(",").split(",")
      groups = current_account.groups.find(:all, :select => "groups.id", :conditions => {:label => params[:party].delete(:group_labels).map(&:strip).reject(&:blank?)})
      params[:party][:group_ids] = groups.map(&:id).join(",") unless groups.empty?
    end
    @party = Party.find_by_account_and_email_address(current_account, params[:email_address][:email_address])
    if @party && @party.confirmed?
      if @party.affiliate_usernames.blank? && session[AFFILIATE_IDS_SESSION_KEY]
        @party.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
      end
      if !params[:party][:tag_list].blank?
        @party.update_attributes!(:tag_list => @party.tag_list + "," + params[:party][:tag_list] + "," + current_domain.name)
        if params[:party][:tag_list] =~ /newsletter/
          flash_success "You've been added to the #{current_domain.name} Newsletter group!"
        end
      end
      if !params[:party][:group_ids].blank?
        groups = current_account.groups.find(params[:party][:group_ids].split(",").map(&:strip).reject(&:blank?))

        # Check if party already belongs to all those groups
        if (@party.groups + groups).uniq.size == @party.groups.uniq.size
          obj = groups.size == 1 ? "group" : "groups"
          flash_failure "You already belong to the #{obj} #{groups.map(&:name).join(", ")}"
          return redirect_to(params[:return_to] || new_session_path)
        else
          if current_user? && (current_user.id == @party.id)
            # If user is logged in, just sign them up to then group
            @party.groups << groups
            @party.groups.uniq!
            @party.update_effective_permissions = true
            group_ids = params[:party].delete(:group_ids)
            [:group_labels, :tag_list].each do |p|
              params[:party].delete(p)
            end unless params[:party].blank?
            @party.attributes=params[:party] unless params[:party].blank?
            @party.save
            obj = groups.size == 1 ? "group" : "groups"
            flash_success "You have successfully subscribed to the #{obj} #{groups.map(&:name).join(", ")}"
            return redirect_to(params[:signed_up] ? params[:signed_up]+"?gids=#{group_ids}" : new_session_path)
          else
            # If not, send them a group subscribe confirmation email
            @party.confirmation_token ||= UUID.random_create.to_s
            @party.confirmation_token_expires_at = @party.account.get_config(:confirmation_token_duration_in_seconds).from_now
            AdminMailer.deliver_group_subscribe_confirmation_email(:route => @party.contact_routes.find_by_type_and_email_address(EmailContactRoute.name, params[:email_address][:email_address]),
                  :confirmation_url => subscribe_party_url(:id => @party.id, :code => @party.confirmation_token, :gids => groups.map(&:id).join(","), 
                  :signed_up => params[:signed_up], :return_to => params[:return_to], :confirm => params[:confirm]),
                  :confirmation_token => @party.confirmation_token, :groups => groups)
            if params[:next]
              return redirect_to(params[:next])
            else
              flash_success "Please check your email and follow the confirmation link to finish the process."
              return redirect_to(new_session_path)
            end
          end
        end
      end      
      # Only show failure message if party is confirmed
      flash_failure "You are already registered" if @party.confirmed?

      return redirect_to(params[:return_to]) if params[:return_to]
      redirect_to new_session_path
    elsif @party && !@party.confirmed?
      #party exists in database, but is not confirmed yet
      if @party.affiliate_usernames.blank? && session[AFFILIATE_IDS_SESSION_KEY]
        @party.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
      end
      
      group_ids = params[:party].delete(:group_ids) if params[:party]
      
      current_account.parties.resignup!(@party, :domain => current_domain, :email_address => params[:email_address], :party => params[:party],
          :group_ids => group_ids, :confirmation_url => lambda {|party, code| confirm_party_url(:id => party, :code => code, :signed_up => params[:signed_up], 
          :return_to => params[:return_to], :confirm => params[:confirm], :gids => group_ids)})
      if params[:next]
        return redirect_to(params[:next].gsub(/__id__/i, @party.id.to_s))
      end
      render_within_public_layout(:action => "signup")
    else
      group_ids = params[:party].delete(:group_ids) if params[:party]
      @party = current_account.parties.signup!(:domain => current_domain, :email_address => params[:email_address], :party => params[:party],
          :group_ids => group_ids, :confirmation_url => lambda {|party, code| confirm_party_url(:id => party, :code => code, :signed_up => params[:signed_up], 
          :return_to => params[:return_to], :confirm => params[:confirm], :gids => group_ids)})
      if @party.affiliate_usernames.blank? && session[AFFILIATE_IDS_SESSION_KEY]
        @party.affiliate_usernames = session[AFFILIATE_IDS_SESSION_KEY]
      end
      @party.save
      if params[:next]
        return redirect_to(params[:next].gsub(/__id__/i, @party.id.to_s))
      end
      render_within_public_layout(:action => "signup")
    end

    rescue ActiveRecord::RecordInvalid
      logger.debug {$!}
      @party = $!.record
      @tags = params[:party][:tag_list]
      @email_address = @party.main_email
      @email_address.attributes = params[:email_address]
      flash_failure @email_address.errors.full_messages.join(", ") unless @email_address.valid?
      return redirect_to(params[:return_to]) if params[:return_to]
      render_within_public_layout(:action => "register")
    rescue ActiveRecord::RecordNotFound
      logger.debug {$!}
      flash_failure $!.message
      return redirect_to(params[:return_to]) if params[:return_to]
      render_within_public_layout(:action => "register")
  end

  def confirm
    @party = current_account.parties.find(params[:id])
    @subscribed_path = params[:signed_up]
    @group_ids = params[:gids]
    @code = params[:code]
    @show_code = false #!params.has_key?(:code)
    
    return redirect_to(params[:confirm]+"?signed_up=#{params[:signed_up]}&code=#{@code}&gids=#{params[:gids]}&pid=#{params[:id]}") if params[:confirm]
    render_within_public_layout

    rescue XlSuite::AuthenticatedUser::ConfirmationTokenExpired
      flash_failure :now, $!.message
      render(:action => "confirmation_token_expired", :status => "400 Bad Request")

    rescue XlSuite::AuthenticatedUser::AuthenticationException, ActiveRecord::RecordNotFound
      render(:action => "bad_token_or_user", :status => "404 Not Found")
  end
  
  def subscribe
    if @party.confirmation_token != params[:confirmation_token]
      flash_failure :now, "Bad token or user.  Please register again."
      return render(:action => "bad_token_or_user", :status => "400 Bad Request")
    end
    @party.account.groups.find(params[:gids].split(",").map(&:strip).reject(&:blank?)).to_a.each do |g|
      @party.groups << g unless @party.groups.include?(g)
    end

    @party.confirm!
    self.current_user = @party
    flash_success "Successfully subscribed to group(s)"
    return redirect_to(params[:signed_up].blank? ? new_session_path : (params[:signed_up] + "?gids=#{params[:gids]}") )
    
  rescue
    flash_failure $!.message
    return redirect_to(params[:return_to] || new_session_path)
  end

  def authorize
    new = !@party.confirmed?
    
    if params[:party][:group_labels]
      params[:party][:group_labels] = params[:party][:group_labels].split(",") if params[:party][:group_labels].is_a?(String)
      # Flatten array such as ["lead", "news, local_news"]
      params[:party][:group_labels] = params[:party][:group_labels].join(",").split(",")
      groups = current_account.groups.find(:all, :select => "groups.id", :conditions => {:label => params[:party].delete(:group_labels).map(&:strip).reject(&:blank?)})
      params[:party][:group_ids] = groups.map(&:id).join(",") unless groups.empty?
    end
    
    params[:gids] = params[:gids].split(",") if params[:gids]
    @party.account.groups.find(params[:party].delete(:group_ids).split(",").map(&:strip).reject(&:blank?)).to_a.each do |g|
      unless @party.groups.include?(g)
        @party.groups << g
        params[:gids] << g.id
      end
    end if params[:party][:group_ids]
    
    @party.save
    @party.authorize!(:attributes => params[:party], :confirmation_token => params[:code])
    self.current_user = @party
    
    affiliate_account = @party.convert_to_affiliate_account!(self.current_domain)
#    if affiliate_account
#      AffiliateAccountNotification.deliver_notification_from_contact_signup(self.current_domain, affiliate_account)
#    end

    flash_success "You have been successfully authorized.  Welcome!"

    redirect_path = params[:signed_up] || params[:next]
    redirect_path.blank? ? (redirect_to_specified_or_default forum_categories_url) : (return redirect_to(params[:gids].blank? ? redirect_path+"?new=#{new}" : redirect_path + "?gids=#{params[:gids].join(",")}&new=#{new}"))

    rescue ActiveRecord::RecordInvalid
      logger.warn $!.message.to_s
      @code = params[:code]
      flash_failure @party.errors.full_messages
      return redirect_to_return_to_or_back_or_home
      #render(:action => "confirm")

    rescue XlSuite::AuthenticatedUser::ConfirmationTokenExpired
      flash_failure :now, "Confirmation token has expired.  Please register again."
      render(:action => "confirmation_token_expired", :status => "400 Bad Request")

    rescue XlSuite::AuthenticatedUser::AuthenticationException
      flash_failure :now, "Bad token or user.  Please register again."
      render(:action => "bad_token_or_user", :status => "400 Bad Request")
  end

  def refresh_inbox
    @party.email_accounts.each do |e|
      e.retrieve!
    end
    redirect_to dashboard_url
  end

  def send_new_password
    @party.reset_password(current_domain.name)

    flash_success "New password sent"
    redirect_to security_party_path(@party)

    rescue
      logger.warn $!.message
      logger.warn $!.backtrace.join("\n")
      flash_failure "Reset password failed"
      redirect_to security_party_path(@party)
  end

  def destroy_collection
    destroyed_items_size = 0
    current_account.parties.find(params[:ids].split(",").map(&:strip)).to_a.each do |party|
      if party == current_user
        flash_failure "You cannot destroy your own account"
      else
        destroyed_items_size += 1 if party.destroy
      end
    end

    flash_success :now, "#{destroyed_items_size} contact(s) successfully deleted"
    respond_to do |format|
      format.js
    end
  end

  def reset_collection_password
    party_ids = params[:ids].split(",").map(&:strip)
    current_account.parties.find(party_ids).to_a.each do |party|
      party.reset_password(current_domain.name)
    end

    message = "The password of selected parties has been reset"
    message = "Password has been reset" if (party_ids.size < 2)

    respond_to do |format|
      format.html do
        flash_success message
        redirect_to parties_path
      end
      format.js do
        flash_success :now, message
        render :action => "tagged_collection"
      end
    end
  end

  def async_tag_parties
    current_account.parties.find(params[:ids].split(",").map(&:strip)).to_a.each do |party|
      party.tag_list = party.tag_list + " #{params[:tag_list]}"
      party.save
    end

    flash_success "Successfully updated Tag List(s) of #{params[:ids].split(',').size} contact(s)"
  end

  def tagged_collection
    current_account.parties.find(params[:ids].split(",").map(&:strip)).to_a.each do |party|
      party.tag_list = party.tag_list + " #{params[:tag_list]}"
      party.save
    end

    respond_to do |format|
      format.html do
        flash_success "Tag list of selected contacts have been successfully updated"
        redirect_to :action => "index"
      end
      format.js do
        flash_success :now, "Tag list of selected contacts have been successfully updated"
      end
    end
  end

  def add_collection_to_group
    group = current_account.groups.find(params[:group_id])

    party_ids = params[:ids].split(",").map(&:strip)
    current_account.parties.find(party_ids).to_a.each do |party|
      party.groups << group if !party.member_of?(group)
    end

    respond_to do |format|
      format.html do
        flash_success "Selected parties are now members of #{group.name} group"
        redirect_to parties_path
      end
      format.js do
        if party_ids.size > 1
          flash_success :now, "Selected parties are now members of #{group.name} group"
        else
          flash_success :now, "Added to #{group.name} group"
        end
        render :action => "tagged_collection"
      end
    end
  end

  def publish_profiles
    party_ids = params[:ids].split(",").map(&:strip)
    parties = current_account.parties.find(:all, :conditions => {:id => party_ids})
      
    count = 0
    fail_count = 0
    ActiveRecord::Base.transaction do
      parties.each do |party|
        if party.profile
          fail_count += 1
          next
        end
        profile = party.to_new_profile
        profile.save!
        party.profile = profile
        party.save!
        if params[:copy_routes]
          party.copy_contact_routes_to_profile!
        end
        count += 1
      end
    end
    
    render :update do |page|
      page << refresh_grid_datastore_with_key("parties")
      page << "$('status-bar-notifications').innerHTML = '#{count} profiles created, #{fail_count} contacts already have profiles setup';"
    end
  end

  def effective_permissions
    effective_permissions = @party.effective_permissions
    effective_permissions_count = @party.effective_permissions.size
    respond_to do |format|
      format.json do
        render :json => {:collection => effective_permissions.map{|p| {:name => p.name.humanize, :id => p.id}}, :total => effective_permissions_count }.to_json
      end
    end
  end

  
  def images
    @images = @party.images
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@images, {:size => params[:size]})
      end
    end
  end
  alias_method :pictures, :images
  
  def multimedia
    @multimedia = @party.multimedia
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@multimedia, {:size => params[:size]})
      end
    end
  end
  
  def other_files
    @other_files = @party.other_files
    respond_to do |format|
      format.js do
        render :json => assemble_images_to_json(@other_files, {:size => params[:size]})
      end
    end
  end
  
  def upload_image
    Account.transaction do
      @picture = current_account.assets.build(:filename => params[:Filename], :uploaded_data => params[:file])
      @picture.content_type = params[:content_type] if params[:content_type]
      @picture.save!
      @view = @party.views.create!(:asset_id => @picture.id, :classification => params[:classification])

      respond_to do |format|
        format.js do
          render :json => {:success => true, :message => 'Upload Successful!'}.to_json
        end
      end
    end

    rescue
      @messages = []
      @messages << @picture.errors.full_messages if @picture
      @messages << @view.errors.full_messages if @view
      logger.debug {"==> #{@messages.to_yaml}"}
      respond_to do |format|
        format.js do
          render :json => {:success => false, :error => @messages.flatten.delete_if(&:blank?).join(',')}.to_json
        end
      end
  end
  
  def extjs_auto_complete
    @parties = []
    
    unless params[:query].blank?
      current_account.parties.find(:all, :limit => 15, :conditions => [ 'LOWER(display_name) LIKE ?',
        '%' + params[:query].downcase + '%' ]).map{|p| @parties << {:display => p.display_name + "   (" + (p.main_email.email_address ? p.main_email.email_address : "") + ")", :value =>p.id}}
    end
    respond_to do |format|
      format.json do
        render :json => {:collection => @parties, :total => @parties.size}.to_json
      end
    end
  end
  
protected
  def load_party
    @party = current_account.parties.find(params[:id])
  end

  # NOP if you have the :edit_party permission.
  def check_own_access
    return true if current_user.can?(:edit_party)
    return true unless @party
    return access_denied unless @party.writeable_by?(current_user)
  end

  def keep_whitelisted_parameters_if_unauthorized
    allow_fields = (self.action_name == "signup")? ALLOWED_SIGNUP_FIELDS : ALLOWED_FIELDS

    (params[:party] || {}).each_pair do |key, value|
      params[:party].delete(key) unless allow_fields.include?(key.to_s)
    end unless current_user? && current_user.can?(:edit_party)
  end

  def choose_layout
    return "no-column" if %w(register signup confirm).include?(self.action_name) && !current_user?
    return "two-columns" if %w(reset_password forgot_password import plaxo address_book register signup confirm authorize).include?(self.action_name)
    return "extjs-grid" if %w(index).include?(self.action_name)
    return "new-party" if %w(new).include?(self.action_name)
    "parties-two-columns"
  end

  def find_parties
    items_per_page = params[:show] || ItemsPerPage
    items_per_page = current_account.parties.count if params[:show] =~ /all/i
    items_per_page = items_per_page.to_i
    sort_params = (params[:sort] || "").strip
    @last_name_asc = @first_name_asc = @company_name_asc = true
    if !sort_params.blank?
      if sort_params.split(",").first =~ /last_name\sasc/i
        @last_name_sort = "last_name desc,first_name asc,company_name asc"
        @last_name_asc = false
      end
      if sort_params.split(",").first =~ /first_name\sasc/i
        @first_name_sort = "first_name desc,last_name asc,company_name asc"
        @first_name_asc = false
      end
      if sort_params.split(",").first =~ /company_name\sasc/i
        @company_name_sort = "company_name desc,last_name asc,first_name asc"
        @company_name_asc = false
      end
    else
      @last_name_sort = "last_name desc,first_name asc,company_name asc"
      @last_name_asc = false
    end

    if params[:q].blank? then
      @pager = ::Paginator.new(current_account.parties.count, items_per_page) do |offset, limit|
        options = {:limit => limit, :offset => offset}
        options = options.merge({:order => sort_params}) unless sort_params.blank?
        current_account.parties.find_all_by_name(options)
      end

      @page = @pager.page(params[:page])
      @parties = @page.items
    else
      if params[:field].blank? then
        @parties = current_account.parties.find_all_by_display_name_like(params[:q])
      else
        raise BadFieldException.new(params[:field], Party) unless Party.content_columns.map(&:name).include?(params[:field])
        @parties = current_account.parties.find(:all, :select => "id, #{params[:field]}, #{params[:field]} display_name",
            :conditions => ["#{params[:field]} LIKE ?", "%#{params[:q]}%"],
            :group => params[:field], :order => params[:field])
      end
    end
  end

  def find_common_party_tags
    @common_tags = current_account.parties.tags(:conditions => ["parties.archived_at IS NULL"],
        :order => "count DESC, name ASC")
  end

  def rescue_action_in_public(e)
    case e
    when BadFieldException
      return render(:text => e.message, :type => "text/plain", :status => "400 Bad Request")
    end

    super
  end

  def process_index
    case params[:dir]
    when "ASC", "DESC"
      sort_dir = params[:dir]
    else
      sort_dir = "ASC"
    end

    fields = case params[:sort]
    when "lastName"
      %w(last_name first_name company_name)
    when "firstName"
      %w(first_name last_name company_name)
    when "company"
      %w(company_name last_name first_name)
    when "displayName"
      %w(display_name company_name last_name first_name)
    end

    search_options = {:offset => params[:start], :limit => params[:limit]}
    search_options.merge!(:order => fields.map {|field| "#{field} #{sort_dir}"}.join(", ")) if fields
    if search_options[:order].blank? && params[:q].blank?
      search_options.merge!(:order => "display_name")
    end

    conditions = []
    params.delete(:group_id) if params[:group_id] =~ /all/i
    if params[:group_id]
      party_ids = current_account.groups.find(params[:group_id]).parties.map(&:id)
      if party_ids.join.blank?
        @parties = []
        @parties_count = 0
        return
      else
        conditions << "(parties.id IN (#{party_ids.join(",")}))" 
      end
    end

    query_params = params[:q]
    unless query_params.blank?
      query_params = query_params.split(/\s+/)
      query_params = query_params.map {|q| q+"*"}.join(" ")
    end
    view_own_contacts_only = current_user.can?(:view_own_contacts_only, :edit_own_contacts_only, :any => true) && !current_user.can?(:view_party, :edit_party, :any => true)
    conditions << "(created_by_id = #{current_user.id} OR parties.id = #{current_user.id})" if view_own_contacts_only
    search_options.merge!(:conditions => conditions.join(" AND ")) unless conditions.blank?

    @parties = current_account.parties.search(query_params, search_options)
    search_options = conditions.blank? ? {} : {:conditions => conditions.join(" AND ")} 

    @parties_count = current_account.parties.count_results(query_params, search_options)
  end

  def load_groups
    @groups = current_account.groups.find(:all, :order => "name")
  end

  def set_routes_instance_variables
    %w(address phone link email).each do |attr|
      instance_variable_set("@new_#{attr}_url", send("new_party_#{attr}_path", @party))
    end
  end
  
  def set_certain_parameters_to_nil
    if params[:party]
      params[:party][:birthdate_day] = nil if params[:party][:birthdate_day] && params[:party][:birthdate_day].blank?
      params[:party][:birthdate_month] = nil if params[:party][:birthdate_month] && params[:party][:birthdate_month].blank?
      params[:party][:birthdate_year] = nil if params[:party][:birthdate_year] && params[:party][:birthdate_year].blank?      
    end
  end
  
  def assemble_records(records)
    out = []
    group = nil
    group = current_account.groups.find(params[:base_group_id]) if params[:base_group_id]
    records.each do |record| 
      out << assemble_record(record, group)
    end
    out
  end
  
  def assemble_record(record, group=nil)
    hash = {
      "id" => record.dom_id,
      "display-name" => record.display_name.to_s,
      "company-name" => record.company_name.to_s,
      "name" => {"first" => record.name.first, "middle" => record.name.middle, "last" => record.name.last},
      "tags" => record.tag_list.to_s,
      "groups" => record.groups.map(&:label).join(", "),
      "position" => record.position.to_s,
      "referral" => record.referal.to_s,
      "phone" => record.main_phone.formatted_number_with_extension.to_s,
      "link" => [record.main_link.url.to_s, record.affiliates ? record.affiliates.map(&:target_url) : nil].flatten.reject(&:blank?).join(", "),
      "email-address" => record.main_email.email_address.to_s,
      "address" => record.main_address.to_s,
      "other-addresses" => record.other_addresses.map {|addr| addr.to_formatted_s(:html => {:tag => "p", :class => "other-address"}) }.join(""),
      "other-emails" => ("<p>" + record.other_emails.map(&:email_address).join("</p><p>") + '</p>').to_s,
      "other-phones" => ('<p>' + record.other_phones.map(&:formatted_number_with_extension).join("</p><p>") + '</p>').to_s,
      "other-websites" => ('<p>' + record.other_links.map(&:url).join("</p><p>") + '</p>').to_s,
      "profile" => !record.profile.blank?
    }
    hash.merge!({ "checked" => true}) if group && record.member_of?(group)
    hash
  end

  ALLOWED_FIELDS = %w(company_name last_name middle_name first_name full_name honorific position group_ids group_labels avatar_id
      signature password password_confirmation old_password tag_list birthdate_day birthdate_month birthdate_year referred_by_id add_domain replace_domains).freeze

  ALLOWED_SIGNUP_FIELDS = ALLOWED_FIELDS
end
