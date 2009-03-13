#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class WelcomeController < ApplicationController
  skip_before_filter :login_required

  # List all links that are available to public view
  def links
    @links = current_account.links.find_for_public
  end
  
  # Implement reciprocal link create
  def create_link
    @link = current_account.links.build
    @link.active_on = Date.today
    @categories_selection = current_account.link_categories.find(:all, :order => "name ASC").map {|x| [x.name, x.id]}
    if request.post?
      @link.reciprocal = true
      @link.title = params[:link][:title]
      @link.address = params[:link][:address]
      @link.reciprocal_address = params[:link][:reciprocal_address]
      @link.link_categories << LinkCategory.find(params[:link][:link_category_id]) unless params[:link][:link_category_id].blank?
      @link.description = params[:link][:description]
      if @link.save
        @link.picture = params[:link][:picture]
        flash[:notice] = 'Thank you for your submission. The link has been sent to our administrators for approval.'
        redirect_to :controller => 'welcome', :action=>'links'
      end      
    end
  end
end
