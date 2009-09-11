#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class AccountDrop < Liquid::Drop
  delegate :title, :owner, :expires_at, :has_payment_gateway?, :to => :account
  attr_reader :account

  def initialize(account=nil)
    @account = account
  end
  
  def blogs
    self.account.blogs
  end
  
  def blog_posts
    self.account.blog_posts.published.by_publication_date
  end
  
  def profile_cities
    self.account.address_contact_routes.all(:conditions => "routable_type = 'Profile' and city is not null", :select => "distinct city").map{|route|route.city.strip}.uniq.sort
  end
  
  def listings
    ListingsDrop.new(self.account)
  end
  
  def domains
    self.account.domains.find(:all, :order => "name")
  end
  
  def browsing_domains
    self.account.domains.find_all_by_role("browsing", :order => "name")
  end
  
  def template_domains
    self.account.domains.find_all_by_role("template", :order => "name")
  end
  
  def country_options_for_select
    AddressContactRoute::COUNTRIES.map{|e|"<option value='#{e.last}'>#{e.first}</option>"}.join("\n")
  end
  
  def state_options_for_select
    AddressContactRoute::STATES.map{|e|"<option value='#{e.last}'>#{e.first}</option>"}.join("\n")    
  end
end
