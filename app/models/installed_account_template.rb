#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class InstalledAccountTemplate < ActiveRecord::Base
  belongs_to :account
  belongs_to :account_template
  
  validates_presence_of :account_id, :account_template_id, :domain_patterns
  validates_uniqueness_of :account_template_id, :scope => [:account_id]
  before_validation :set_default_domain_patterns
  
  belongs_to :account_module_subscription
  validates_presence_of :account_module_subscription_id
  
  acts_as_money :subscription_markup_fee, :setup_fee

  def update_from_account_template!(options={})
    ActiveRecord::Base.transaction do
      return false unless self.account_template && self.account_template.stable_account
      options = options.dup.symbolize_keys
      exclude_items = options.delete(:exclude_items)
      options[:exclude_pages] = []
      options[:exclude_layouts] = []
      options[:exclude_snippets] = []
      if exclude_items
        exclude_items.split(",").map(&:strip).each do |exclude_item|
          case exclude_item
          when /page/i
            options[:exclude_pages] << exclude_item.split("_").map(&:strip).last.to_i
          when /snippet/i
            options[:exclude_snippets] << exclude_item.split("_").map(&:strip).last.to_i
          when /layout/i
            options[:exclude_layouts] << exclude_item.split("_").map(&:strip).last.to_i
          else
            raise StandardError, "Exclude item contains non supported type #{exclude_item}" 
          end
        end
      end
      options.reverse_merge!({
        :pages => true, :snippets => true, :layouts => true,
        :groups => false,
        :assets => false, 
        :products => false, 
        :contacts => false,
        :blogs => false,
        :workflows => false,
        :feeds => false})
      domain_patterns = options.delete(:domain_patterns) || "**"
      options.merge!(:domain_patterns => domain_patterns)
      options.merge!(:target_account_id => self.account.id)
      options.merge!(:modified => false)
      update_futures = []
      if options[:layouts]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_layouts_to!)
        object_pushed = true
      end
      if options[:snippets]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_snippets_to!)
        object_pushed = true
      end
      if options[:pages]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_pages_to!)
        object_pushed = true
      end
      if options[:groups]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_groups_and_roles_to!)
        object_pushed = true
      end
      if options[:assets]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_assets_to!)
        object_pushed = true
      end
      if options[:configurations]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_configurations_to!)
        object_pushed = true
      end
      if options[:products]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_products_and_product_categories_to!)
        object_pushed = true
      end
      if options[:contacts]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_contacts_to!)
        object_pushed = true
      end
      if options[:blogs]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_blogs_and_blog_posts_to!)
        object_pushed = true
      end
      if options[:workflows]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_workflows_to!)
        object_pushed = true
      end
      if options[:feeds]
        update_futures << MethodCallbackFuture.create!(:account => self.account, :model => self.account_template.stable_account, :params => options, :method => :copy_all_feeds_to!)
        object_pushed = true
      end
      return false unless object_pushed
      update_futures = MethodCallbackFuture.create!(:models => [self], :account => self.account, :method => :callbacks_after_template_update, :repeat_until_true => true, 
            :params => {:future_ids => update_futures.map(&:id), :target_account_id => self.account.id}, :priority => 75)
      true
    end
  end
  
  def callbacks_after_template_update(args)
    future_ids = args[:future_ids]
    status_hash = Future.get_status_of(future_ids)
    if status_hash['isCompleted']
      AdminMailer.deliver_template_updated_email(self.account, self.account_template)
      return true
    end
    return false
  end
  
  def compare_with(target_acct)
    result = []
    return result unless self.account_template.stable_account
    stable_acct = self.account_template.stable_account
    stable_acct.layouts.all(:conditions => {:no_update => false}).each do |layout|
      l = target_acct.layouts.find(:first, :conditions => {:uuid => layout.uuid, :no_update => false})
      if l
        result << l if ((l.content_attributes != layout.content_attributes) and (l.modified or l.modified == nil))
      end
    end
    %w(pages snippets).each do |relation|
      stable_acct.send(relation).all(:conditions => {:no_update => false}).each do |object|
        o = target_acct.send(relation).find(:first, :conditions => {:uuid => object.uuid, :no_update => false})
        if o
          result << o if ((o.content_attributes != object.content_attributes) and (o.modified or o.modified==nil))
        end
      end
    end
    result
  end
  
  def list_no_update_items_with(target_acct)
    result = []
    stable_acct = self.account_template.stable_account
    return result unless stable_acct
    # layouts
    t_acct_nu_layout_uuids = target_acct.layouts.all(:select => "uuid", :conditions => {:no_update => true}).map(&:uuid)
    s_acct_layout_uuids = stable_acct.layouts.all(:select => "uuid").map(&:uuid)
    temp = t_acct_nu_layout_uuids & s_acct_layout_uuids
    result += target_acct.layouts.all(:conditions => {:uuid => temp}, :order => "title ASC") unless temp.empty?
    # pages
    t_acct_nu_page_uuids = target_acct.pages.all(:select => "uuid", :conditions => {:no_update => true}).map(&:uuid)
    s_acct_page_uuids = stable_acct.pages.all(:select => "uuid").map(&:uuid)
    temp = t_acct_nu_page_uuids & s_acct_page_uuids
    result += target_acct.pages.all(:conditions => {:uuid => temp}, :order => "fullslug ASC") unless temp.empty?
    # snippets
    t_acct_nu_snippet_uuids = target_acct.snippets.all(:select => "uuid", :conditions => {:no_update => true}).map(&:uuid)
    s_acct_snippet_uuids = stable_acct.snippets.all(:select => "uuid").map(&:uuid)
    temp = t_acct_nu_snippet_uuids & s_acct_snippet_uuids
    result += target_acct.snippets.all(:conditions => {:uuid => temp}, :order => "title ASC") unless temp.empty?
    result
  end
  
  protected
  
  def set_default_domain_patterns
    self.domain_patterns = "**" if self.domain_patterns.blank?
  end
end
