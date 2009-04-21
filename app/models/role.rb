#- XLsuite, an integrated CMS, CRM and ERP for medium businesses
#- Copyright 2005-2009 iXLd Media Inc.  See LICENSE for details.

# Defines a grouping of permissions assigned to something (a group, an individual party).
#
# == Data Flow
#
# Parties propagate downards: a child role inherits it's parent's parties.  See #total_parties.
# Permissions propagate upwards: a parent role inherits it's children's permissions.  See #total_granted_permissions.
class Role < ActiveRecord::Base
  belongs_to :account
  validates_presence_of :account_id
  before_validation :assign_account_id

  # Relationships
  acts_as_tree
  has_many :permission_grants, :as => :assignee, :dependent => :delete_all
  has_many :permissions, :through => :permission_grants, :source => :subject, :source_type => "Permission", :order => "permissions.name"
  
  has_many :permission_denials, :as => :assignee, :dependent => :delete_all
  has_many :denied_permissions, :through => :permission_denials, :source => :subject, :source_type => "Permission", :order => "permissions.name"  
  
  has_many :permission_grant_subjects, :as => :subject, :dependent => :delete_all, :class_name => "PermissionGrant"
  has_many :groups, :through => :permission_grant_subjects, :source => :assignee, :source_type => "Group", :order => "groups.name"
  
  has_many :parties, :through => :permission_grant_subjects, :source => :assignee, :source_type => "Party"

  belongs_to :created_by, :class_name => "Party", :foreign_key => "created_by_id"
  belongs_to :updated_by, :class_name => "Party", :foreign_key => "updated_by_id"

  # Validations
  validates_presence_of :name
  validates_length_of :name, :within => (1 .. 240)
  validates_uniqueness_of :name, :scope => [:account_id, :parent_id]
  validate :children_not_any_of_my_parents
  
  before_save :set_old_object
  
  after_save :add_children
  after_save :update_parties_effective_permissions
  after_create :set_parties_effective_permissions
  after_destroy :set_parties_effective_permissions
  
  attr_accessor :new_ids

  include XlSuite::Permissionable
  
  def children_not_any_of_my_parents
    if new_ids
      string_ids = new_ids.map{|id| id.to_s}
      self.errors.add_to_base("Recursive groups/permission sets aren't allowed") if (string_ids + self.ancestors.map{|a| a.id.to_s}).uniq!
    end
  end

  def children_ids
    self.children.map(&:id)
  end

  def children_ids=(new_ids)
    self.new_ids = new_ids
  end

  def permission_ids
    self.permissions.map(&:id)
  end

  def permission_ids=(new_ids)
    new_ids = (new_ids || []).reject(&:blank?)
    old_ids = []
    if !self.new_record? 
      old_ids = self.reload.permission_ids
    end
    self.class.transaction do
      PermissionGrant.delete_all({:subject_type => "Permission", :subject_id => old_ids - new_ids, :assignee_id => self.id, 
          :assignee_type => self.class.send(:class_of_active_record_descendant, self.class).name }) \
          unless old_ids.empty? || self.new_record?
      (new_ids - old_ids).each do |permission_id|
        self.permission_grants.build(:subject_type => "Permission", :subject_id => permission_id)
      end
    end
  end

  def members
    self.children + self.parties
  end

  def to_s
    self.name
  end

  def self.find_all_roots(options={})
    with_scope(:find => {:conditions => {:parent_id => nil}}) do
      find(:all, options)
    end
  end

  def total_parties
    x = self.groups.inject([]) {|memo, group| memo << group.total_parties}
    x << self.parent.total_parties if self.parent
    x << self.parties
    x.flatten.uniq
  end
  
  def attributes_for_copy_to(account)
    account_owner_id = account.owner ? account.owner.id : nil
    self.attributes.dup.symbolize_keys.merge(:account_id => account.id, :created_by_id => account_owner_id, 
          :updated_by_id => account_owner_id)
  end
  
  def copy_permissions_and_child_roles_from!(role)
    PermissionGrant.create_collection_by_assignee_and_subjects(self, role.permissions) unless role.permissions.blank?
    PermissionDenial.create_collection_by_assignee_and_subjects(self, role.denied_permissions) unless role.denied_permissions.blank?
    
    role.children.each do |child_role|
      new_role = self.account.roles.find_by_name(child_role.name)
      new_role ||= self.account.roles.build(child_role.attributes_for_copy_to(self.account))

      new_role.parent_id = self.id
      new_role.save!
      new_role.copy_permissions_and_child_roles_from!(child_role)
    end
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
    old_ids = self.children_ids
    self.class.transaction do
      self.class.update_all(["parent_id = ?", nil], ["id IN (?)", old_ids]) unless old_ids.blank?
      self.class.update_all(["parent_id = ?", self.id], ["id IN (?)", new_ids]) unless new_ids.blank?
    end
  end
  
  def set_old_object
    @old_object = self.class.find_by_id(self.id)
  end
  
  def update_parties_effective_permissions
    if @old_object && (@old_object.parent_id != self.parent_id)
      self.set_parties_effective_permissions
    end
    true
  end
  
  def set_parties_effective_permissions
    x = self.total_parties
    MethodCallbackFuture.create!(:models => x, :account =>  self.account, :method => :generate_effective_permissions, :priority => 0) unless x.empty?
  end
end
