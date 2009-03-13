#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

class Group < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation :assign_account_id
  
  acts_as_taggable
  acts_as_reportable

  named_scope :public, :conditions => ["private = 0"]
  named_scope :private, :conditions => ["private = 1"]
  
  belongs_to :avatar, :class_name => "Asset", :foreign_key => "avatar_id"
  
  # Relationships
  acts_as_tree
  has_many :permission_grants, :as => :assignee, :dependent => :delete_all
  has_many :permissions, :through => :permission_grants, :source => :subject, :source_type => "Permission", :order => "permissions.name"
  
  has_many :permission_denials, :as => :assignee, :dependent => :delete_all
  has_many :denied_permissions, :through => :permission_denials, :source => :subject, :source_type => "Permission", :order => "permissions.name"  
  
  has_many :roles, :through => :permission_grants, :source => :subject, :source_type => "Role", :order => "roles.name"
  
  has_many :memberships
  has_many :parties, :order => "parties.display_name", :through => :memberships
  
  has_many :group_items, :dependent => :delete_all
  has_many :products, :through => :group_items, :source => :target, :source_type => "Product", :order => "position"

  belongs_to :created_by, :class_name => "Party", :foreign_key => "created_by_id"
  belongs_to :updated_by, :class_name => "Party", :foreign_key => "updated_by_id"

  has_many :authorizations, :dependent => :destroy

  include XlSuite::PicturesHelper

  # Validations
  validates_presence_of :name
  validates_length_of :name, :within => (1 .. 240)
  
  validates_presence_of :label
  validates_length_of :label, :within => (1..240)
  validates_uniqueness_of :label, :scope => [:account_id]
  validates_format_of :label, :with => /\A[-\w]+\Z/i, :message => "can contain only a-z, A-Z, 0-9, _ and -, cannot contain space(s)"

  validate :children_not_any_of_my_parents
  
  before_validation :set_name_if_blank
  
  after_save :add_children

  attr_accessor :new_ids

  include XlSuite::Permissionable
  
  def total_granted_permissions
    perms = self.permissions
    self.roles.each do |role|
      perms += role.total_granted_permissions
    end
    perms += self.ancestors.map(&:total_granted_permissions)
    perms.flatten!
    perms.uniq!
    perms
  end
  
  def total_denied_permissions
    denied_perms = self.denied_permissions
    self.roles.each do |role|
      denied_perms += role.total_denied_permissions
    end
    denied_perms += self.ancestors.map(&:total_denied_permissions)
    denied_perms.flatten!
    denied_perms.uniq!
    denied_perms
  end

  def total_parties
    (self.children.map(&:total_parties) + self.parties).flatten.uniq
  end

  # TODO: this method does not make sense but needed to use XlSuite::Permissionable
  def groups
    self.children
  end  
    
  def members
    self.children + self.parties
  end

  def to_s
    self.name
  end

  def to_liquid
    GroupDrop.new(self)
  end

  def children_ids
    self.children.find(:all, :select => "#{self.class.table_name}.id").map(&:id)
  end

  def children_ids=(new_ids)
    self.new_ids = new_ids
  end

  def permission_ids
    self.permissions.map(&:id)
  end

  def permission_ids=(new_ids)
    new_ids = (new_ids || []).reject(&:blank?)
    old_ids = self.permission_ids
    self.class.transaction do
      PermissionGrant.delete_all({:permission_id => old_ids - new_ids, :assignee_id => self.id, 
          :assignee_type => self.class.send(:class_of_active_record_descendant, self.class).name }) \
          unless old_ids.empty? || self.new_record?
      (new_ids - old_ids).each do |permission_id|
        self.permission_grants.build(:permission_id => permission_id)
      end
    end
  end

  def self.find_all_roots(options={})
    with_scope(:find => {:conditions => {:parent_id => nil}}) do
      find(:all, options)
    end
  end
  
  def member_of?(object)
    return false unless object.kind_of?(Role)
    count = PermissionGrant.count(["subject_type=? AND subject_id=? AND assignee_type=? AND assignee_id=?", object.class.name, object.id, self.class.name, self.id])
    return true if count > 0
    false
  end
  
  def attributes_for_copy_to(account)
    account_owner_id = account.owner ? account.owner.id : nil
    attributes = self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :created_by_id => account_owner_id, 
          :updated_by_id => account_owner_id, :parent_id => nil, :tag_list => self.tag_list)
    avatar = account.assets.create!(self.avatar.attributes_for_copy_to(account)) if self.avatar
    attributes.merge!(:avatar_id => avatar.blank? ? nil : avatar.reload.id ) 
    attributes
  end
  
  def copy_child_groups_from!(group)
    group.children.each do |child_group|
      new_group = self.account.groups.find_by_label(child_group.label)
      new_group ||= self.account.groups.build(child_group.attributes_for_copy_to(self.account))

      new_group.parent_id = self.id
      new_group.save!
      new_group.copy_child_groups_from!(child_group)
    end
  end
  
  def public?
    !self.private?
  end
  
  def join!(party)
    return false if self.new_record?
    m = Membership.find(:first, :conditions => {:party_id => party.id, :group_id => self.id})
    return false if m
    Membership.create!(:group => self, :party => party)
  end

  protected
  def assign_account_id
    if self.parent then
      self.account = self.parent.account
    elsif self.parent_id then
      self.class.with_scope({}, :replace) do
        self.account = self.class.find(self.parent_id).account
      end
    end if self.account.blank?
  end

  def add_children
    new_ids = self.new_ids
    new_ids = (new_ids || []).reject(&:blank?)
    return if new_ids.empty?
    
    old_ids = self.children_ids
    self.class.transaction do
      self.class.update_all(["parent_id = ?", nil], ["id IN (?)", old_ids]) unless old_ids.blank?
      self.class.update_all(["parent_id = ?", self.id], ["id IN (?)", new_ids]) unless new_ids.blank?
    end
  end

  def children_not_any_of_my_parents
    if new_ids
      string_ids = new_ids.map{|id| id.to_s}
      self.errors.add_to_base("Recursive groups aren't allowed") if (string_ids + self.ancestors.map{|a| a.id.to_s}).uniq!
    end
  end
  
  def set_name_if_blank
    self.name = self.label if self.name.blank?
  end    
end
