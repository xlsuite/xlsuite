#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

module PostsHelper
  
  def search_posts_title
    returning (params[:q].blank? ? 'Recent Posts' : "Searching for '#{h params[:q]}'") do |title|
      title << " by #{h Party.find(params[:user_id]).display_name}" if params[:user_id]
      title << " in #{h Forum.find(params[:forum_id]).name}"       if params[:forum_id]
    end
  end
  
end
