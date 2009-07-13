#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class SuitesController < ApplicationController
  required_permissions :none
  
  def index
    respond_to do |format|
      format.js
    end
  end
  
  def embed_code
    affiliate_username = nil
    if params[:affiliate_id].blank?
      affiliate_username = self.current_user? ? self.current_user.affiliate_username : ""
    else
      affiliate_username = params[:affiliate_id]
    end
    per_page = params[:per_page].to_i
    @embed_code = %Q~<script type="text/javascript">
  var xlsuiteAffiliateId = "#{affiliate_username}";
  var xlsuiteEmbedSuitesReferralDomain = "#{self.current_domain.name}";
  var xlsuiteEmbedSuitesCurrentPageNum = 1;
  var xlsuiteEmbedSuitesPerPage = #{per_page};
</script>
<script type="text/javascript" src="#{self.absolute_current_domain_url}/javascripts/xl_suite/suites_catalog_embed_extjs.js"></script>
<script type="text/javascript" src="#{self.absolute_current_domain_url}/javascripts/xl_suite/suites_catalog_embed.js"></script>
~
    @embed_code << %Q~<link type="text/css" rel="stylesheet" href="#{self.absolute_current_domain_url}/stylesheets/suites_catalog_embed.css"/>
<!--[if gte IE 6]>
<style>
li.xlsuite-embed-suite-item h2 a.xlsuite_install_button {top: 5px; right: 13px;}
</style>
<![endif]-->    
~ if params[:include_css]
    @embed_code << %Q~<div id="xlsuite-embed-suites-catalog">
~
    @embed_code << if params[:include_search_bar]
      %Q~  <div id="xlsuite-embed-suites-search-bar">
~
    else
      %Q~  <div id="xlsuite-embed-suites-search-bar" style="display:none;">
~
    end
    @embed_code << %Q~    <form id="xlsuite-embed-suites-search-bar-form" action="">
~
    @embed_code << %Q~      <input type="text" id="xlsuite-embed-suites-search-bar-query" name="query"/>
~ if params[:include_search_bar]
    @embed_code << if params[:industry].blank? && params[:include_search_bar]
      %Q~      <span id="xlsuite-embed-suites-search-bar-industries-container"></span>
~
    else
      %Q~      <input type="hidden" name="industry" value="#{params[:industry]}"/>
~
    end

    @embed_code << if params[:main_theme].blank? && params[:include_search_bar]
      %Q~      <span id="xlsuite-embed-suites-search-bar-main_themes-container"></span>
~
    else
      %Q~      <input type="hidden" name="main_theme" value="#{params[:main_theme]}"/>
~
    end
    
    @embed_code << if params[:mode] =~ /tag/i && !params[:tags].blank?
        %Q~      <input type="hidden" name="tag_list" value="#{Tag.parse(params[:tags]).join(',')}"/>
~
      else
        %Q~      <span id="xlsuite-embed-suites-search-bar-tag_list-container"></span>
~
      end

    @embed_code << %Q~      <input type="hidden" name="ids" value="#{params[:ids]}" />
~ unless params[:ids].blank?
    
    @embed_code << %Q~      <input id="xlsuite-embed-suites-search-bar-button" type="submit" value="Search">
~ if params[:include_search_bar]
    @embed_code << %Q~    </form>
  </div>
  <div id="xlsuite-embed-suites-collection"><ul id="xlsuite-embed-suites-selection"></ul></div>
  <div id="xlsuite-embed-suites-paging" class="xlsuite-embed-suites-paging"></div>
</div>~
    
    respond_to do |format|
      format.js do
        render(:json => {:code => @embed_code, :success => true}.to_json)
      end
    end
  end
  
  def destroy_collection
    @destroyed_items_size = 0
    @undestroyed_items_size = 0
    AccountTemplate.find(params[:ids].split(",").map(&:strip)).each do |suite|
      if suite.destroy
        @destroyed_items_size += 1
      else
        @undestroyed_items_size += 1
      end
    end

    error_message = []
    error_message << "#{@destroyed_items_size} suites(s) successfully deleted" if @destroyed_items_size > 0
    error_message << "#{@undestroyed_items_size} suite(s) failed to be destroyed" if @undestroyed_items_size > 0

    flash_success :now, error_message.join(", ")
    respond_to do |format|
      format.js do 
        render :template => "suites/approve_collection.rjs", :layout => false
      end
    end
  end
  
  def approve_collection
    @approved_size = 0
    AccountTemplate.find(params[:ids].split(",").map(&:strip)).each do |suite|
      suite.approve!(self.current_user)
      @approved_size += 1
    end
    flash_success :now, "#{@approved_size} suite(s) successfully approved"
    respond_to do |format|
      format.js
    end  
  end
  
  def unapprove_collection
    @unapproved_size = 0
    AccountTemplate.find(params[:ids].split(",").map(&:strip)).each do |suite|
      suite.unapprove!(self.current_user)
      @unapproved_size += 1
    end
    flash_success :now, "Unapproved #{@unapproved_size} suite(s)"
    respond_to do |format|
      format.js do
        render :template => "suites/approve_collection.rjs", :layout => false
      end
    end    
  end
  
  def install
    respond_to do |format|
      format.js
    end
  end
  
  protected
  def authorized?
    return true if %w(index embed_code).include?(self.action_name)
    return false unless self.current_user?
    if %w(install).include?(self.action_name)
      return self.current_user_is_account_owner?
    end
    self.current_user.superuser?
  end
end
