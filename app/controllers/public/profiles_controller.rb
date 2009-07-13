#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Public::ProfilesController < ApplicationController
  # check authorized?
  required_permissions :none

  before_filter :load_product_categories, :only => [:attach_product_categories, :detach_product_categories]

  def change_password
    party = @profile.party
    if params[:reset]
      party.reset_password(current_domain.name)
      message = %Q`<p>The password for <b>#{party.name.to_s.upcase}</b> has been reset.</p><p>An email containing the new password has been sent to #{party.main_email.email_address}</p>`
      respond_to do |format|
        format.js do
          return render(:json => {:success => true, :messages => message}.to_json)
        end
        format.html do
          flash_success message
          redirect_to_next_or_back_or_home
        end
      end
    else
      begin
        party.change_password!(:old_password => params.delete(:old_password),
                               :password => params.delete(:password),
                               :password_confirmation => params.delete(:password_confirmation))
        respond_to do |format|
          message = "Password successfully changed"
          format.js do
            return render(:json => {:success => true, :messages => message}.to_json)
          end
          format.html do
            flash_success message
            redirect_to_next_or_back_or_home
          end
        end
      rescue XlSuite::AuthenticatedUser::BadAuthentication
        respond_to do |format|
          message = "Password is wrong"
          format.js do
            return render(:json => {:success => false, :messages => message}.to_json)
          end
          format.html do
            flash_failure message
            redirect_to_return_to_or_back_or_home
          end
        end
      rescue ActiveRecord::RecordInvalid
        respond_to do |format|
          message = $!.message
          format.js do
            return render(:json => {:success => false, :messages => message}.to_json)
          end
          format.html do
            flash_failure message
            redirect_to_return_to_or_back_or_home
          end
        end
      end
      
    end
  end

  def attach_product_categories
    messages, errors = [], []
    if @all_categories_permitted
      party = @profile.party
      party.product_category_ids = (party.product_category_ids + @category_ids_param).uniq
      party.save!
      messages << "Product categories successfully attached"
    else
      errors << "Please select only public product categories"
    end
    respond_to do |format|
      format.html do
        if @all_categories_permitted
          flash_success messages.first
        else
          flash_failure errors.first
        end
        return @all_categories_permitted ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render(:json => {:success => @all_categories_permitted, :errors => errors, :messages => messages})
      end
    end
  end

  def detach_product_categories
    messages, errors = [], []
    if @all_categories_permitted
      party = @profile.party
      party.product_category_ids = party.product_category_ids - @category_ids_param
      party.save!
      messages << "Product categories successfully detached"
    else
      errors << "Please select only public product categories"
    end
    respond_to do |format|
      format.html do
        if @all_categories_permitted
          flash_success messages.first
        else
          flash_failure errors.first
        end
        return @all_categories_permitted ? redirect_to_next_or_back_or_home : redirect_to_return_to_or_back_or_home
      end
      format.js do
        render(:json => {:success => @all_categories_permitted, :errors => errors, :messages => messages})
      end
    end
  end
  
  def check_alias
    taken = true
    if params[:alias].blank?
      taken = false
    else
      taken = (self.current_account.profiles.find_by_alias(params[:alias]) ? true : false)
    end
    respond_to do |format|
      format.js do
        render(:json => {:taken => taken}.to_json)
      end
    end
  end
  
  def check_custom_url
    taken = true
    if params[:custom_url].blank?
      taken = false
    else
      taken = (self.current_account.profiles.find_by_custom_url(params[:custom_url]) ? true : false)
    end
    respond_to do |format|
      format.js do
        render(:json => {:taken => taken}.to_json)
      end
    end
  end
  
  def auto_complete
    @profiles = []
    display_text = ""
    contact_routes = []
    if !params[:query].blank? && params[:query].size > 1
      self.current_account.profiles.find(:all, :limit => 15, :conditions => 
          ['LOWER(display_name) LIKE ? OR LOWER(display_name) LIKE ? OR LOWER(display_name) LIKE ?', 
          '%' + params[:query].downcase + '%',
          '%' + params[:query].downcase,
          params[:query].downcase + '%']).each do |profile|
        display_text = profile.display_name
        contact_routes = []
        contact_routes << (profile.main_email.email_address ? profile.main_email.email_address : "") if params[:with_email]
        contact_routes << (profile.main_phone.number ? profile.main_phone.number : "") if params[:with_phone]
        contact_routes << (profile.main_url.number ? profile.main_link.url : "") if params[:with_link]
        contact_routes = contact_routes.reject(&:blank?)
        display_text += "   (" + contact_routes.join(", ") + ")" if !contact_routes.empty?
        @profiles << {:display => display_text, :id => profile.id}
      end
    end
    respond_to do |format|
      format.json do
        render :json => {:collection => @profiles, :total => @profiles.size}.to_json
      end
    end
  end

  def embed_code
    success = true
    errors = []
    snippet = self.current_account.snippets.find_by_title(self.current_domain.get_config("profile_embed_code_snippet"))
    if snippet
      affiliate_username = self.current_user? ? self.current_user.affiliate_username : ""
      liquid_assigns = {"profile" => @profile, "domain" => self.current_domain.to_liquid,
        "user" => PartyDrop.new(self.current_user), "logged_in" => self.current_user?,
        "user_affiliate_username" => affiliate_username, "user_affiliate_id" => affiliate_username}
      registers = {"account" => self.current_account, "domain" => self.current_domain}
      liquid_context = Liquid::Context.new(liquid_assigns, registers, false)
      @text = Liquid::Template.parse(snippet.body).render!(liquid_context)
    else
      success = false
      errors << "Profile embed code snippet cannot be found. Please check your configuration 'profile_embed_code_snippet'"
    end
    respond_to do |format|
      format.js do
        render(:json => {:success => success, :errors => errors, :title => @profile.display_name, :text => @text}.to_json)
      end
    end
  end
  protected

  def load_profile
    @profile = self.current_account.profiles.find(params[:id])
  end

  def load_product_categories
    @category_ids_param = params[:product_category_ids].split(",").map(&:strip).map(&:to_i)
    @product_categories_count = self.current_account.product_categories.count(:conditions => {:id => @category_ids_param, :private => false})
    @all_categories_permitted = @category_ids_param.size == @product_categories_count
  end

  def authorized?
    if %w(attach_product_categories detach_product_categories change_password).include?(self.action_name)
      return false unless self.current_user?
      self.load_profile
      return true if self.current_user.can?(:edit_profiles)
      return self.current_user.id == @profile.party.id
    elsif %(check_alias check_custom_url).include?(self.action_name)
      return true
    elsif %w(auto_complete).include?(self.action_name)
      return self.current_user?
    elsif %w(embed_code).include?(self.action_name)
      self.load_profile
      return true
    else
      return false
    end
    false
  end
end
