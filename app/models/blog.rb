#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Blog < ActiveRecord::Base
  include XlSuite::Commentable
  acts_as_taggable

  acts_as_fulltext %w(title), %w(subtitle label author_name)
  acts_as_reportable :columns => %w(title subtitle label author_name comment_approval_method)

  belongs_to :account
  belongs_to :domain
  has_many :posts, :class_name => "BlogPost", :dependent => :destroy

  belongs_to :owner, :class_name => "Party", :foreign_key => :owner_id
  belongs_to :created_by, :class_name => "Party", :foreign_key => :created_by_id
  belongs_to :updated_by, :class_name => "Party", :foreign_key => :updated_by_id

  validates_presence_of :account_id, :domain_id, :title, :author_name, :label, :owner_id, :created_by_id
  validates_uniqueness_of :label, :scope => :account_id
  validates_format_of :label, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)"
  has_many :accessible_items, :class_name => "ProductItem", :as => :item
  has_many :products, :through => :accessible_items, :as => :item
  before_save :set_author_name

  include XlSuite::AccessRestrictions

  # Returns the date at which this blog was last updated, meaning when was the last post published.
  # atom:updated element reference: http://www.atomenabled.org/developers/syndication/atom-format-spec.php#element.updated
  # The specification says atom:updated should be the date of the last *significant* change.
  # For the moment, let's leave published_at as the last significant event.  Eventually, we might want to
  # have 2 dates: significant_updated_at and updated_at.
  def last_updated_at
    self.posts.published.first(:select => "MAX(published_at) published_at").published_at
  end

  def public?
    !self.private
  end
  
  def private?
    self.private
  end

  def readable_by?(party)
    return true if self.new_record?
    return true if self.owner_id == party.id if party
    if self.public?
      return true if self.readers.empty?
      return false unless party
      return (self.readers + self.writers).uniq.any? do |group|
        party.member_of?(group)
      end
    else
      return false unless party
      return true if party.granted_blogs.map(&:id).include?(self.id)
      expiring_item = party.expiring_items.find(:first, :conditions => ["item_type=? AND item_id=? AND (expired_at IS NULL OR expired_at > ?)", self.class.name, self.id, Time.now.utc])
      return !expiring_item.nil?
    end
  end

  def to_liquid
    BlogDrop.new(self)
  end

  def count_by_month(cutoff_at = 10.years.ago)
    self.posts.count_by_month(cutoff_at)
  end  

  def attributes_for_copy_to(account)
    account_owner_id = account.owner ?  account.owner.id : nil
    account_owner_name = if account.owner
        account.owner.full_name.blank? ? account.owner.display_name : account.owner.full_name
      else
        ""
      end
    self.attributes.dup.symbolize_keys.merge(:account_id => nil, :account => account, :tag_list => self.tag_list, 
    :author_name => account_owner_name, 
    :created_by_id => account_owner_id, :updated_by_id => nil, :owner_id => account_owner_id)
  end

  def author
    self.owner
  end
  
  def author_profile
    self.owner.profile
  end

  protected

  def set_author_name
    return unless self.owner
    self.author_name = self.owner.name.to_s if self.author_name.blank?
  end
end
