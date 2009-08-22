class CachedPage < ActiveRecord::Base
  belongs_to :account
  belongs_to :domain
  belongs_to :page
  
  validates_presence_of :account_id, :domain_id, :page_id, :cap_visit_num, :visit_num, :next_refresh_at, :refresh_period_in_seconds
  validates_uniqueness_of :uri, :scope => [:account_id, :domain_id]
  
  # This method creates MethodCallbackFuture to refresh the page when visit_num is bigger than cap_visit_num
  # or if next_refreshed_at has passed
  # Increment visit_num attribute by 1
  def refresh_check!
    self.update_attribute(:visit_num, self.visit_num + 1)
    if !self.refresh_requested? && (self.cap_visit_num <= self.visit_num || self.next_refresh_at <= Time.now.utc)
      self.update_attribute(:refresh_requested, true)
      MethodCallbackFuture.create!(:priority => 110, :account => page.account, :owner => page.account.owner, :model => self, :method => "refresh!")
    end
  end

  # This method refresh the rendered_content and rendered_content_type attributes
  def refresh!
    cart = self.account.carts.build
    cart.domain = self.domain

    t_paths, t_params = self.uri.split("?")
    t_paths.gsub!(/\/\Z/i, "") if (t_paths && t_paths != "/")
    t_paths = "/" if t_paths.blank?
    
    # get page with its params
    t_page, page_params = self.domain.recognize!(t_paths)
    self.page = t_page
    self.page_fullslug = self.page.fullslug

    params = {}
    if t_params
      t_params.gsub!(/#.*/i, "")
      t_params = t_params.split("&") 
      t_params.each do |t_param|
        key, value = t_param.split("=")
        # sometimes a param doesn't have value
        params[key] = CGI::unescape(value) if value
      end
    end
    params.merge!(page_params)
       
    options = {:current_account => self.account, :current_account_owner => self.account.owner,
      :tags => TagsDrop.new, :user_affiliate_username => "",
      :current_page_url => ("http://" + self.domain.name + self.uri), :current_page_slug => self.uri, :cart => cart,
      :flash => {:errors => "", :messages => "", :notices => ""},
      :params => params, :logged_in => false}

    render_options = self.page.render_on_domain(self.domain, options)
    self.rendered_content = render_options[:text]
    self.rendered_content_type = render_options[:content_type]

    self.next_refresh_at = Time.now.utc + self.refresh_period_in_seconds
    self.last_refreshed_at = Time.now.utc
    self.visit_num = 0
    self.refresh_requested = false
    self.save!
  end
  
  def self.create_from_uri_page_and_domain(uri, page, domain, other_attributes={})
    cached_page = self.new(:account_id => page.account_id, :domain_id => domain.id, 
      :page_id => page.id, :page_fullslug => page.fullslug || "", :uri => uri,
      :cap_visit_num => 5, :visit_num => 0,
      :next_refresh_at => Time.now.utc, :refresh_period_in_seconds => 54000)
    cached_page.attributes = other_attributes
    saved = cached_page.save
    if saved
      MethodCallbackFuture.create!(:priority => 110, :account => page.account, :owner => page.account.owner, :model => cached_page, :method => "refresh!")
    end
    saved
  end
end
